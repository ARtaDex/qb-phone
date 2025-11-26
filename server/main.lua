local ESX = exports['es_extended']:getSharedObject()
local QBPhone = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local GeneratedPlates = {}
local WebHook = '' -- Masukkan Webhook Discord Anda di sini
local FivemerrApiToken = ''
local bannedCharacters = { '%', '$', ';' }
local TWData = {}

-- Functions

local function GetPlayerByPhone(number)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        -- Asumsi kolom database untuk nomor hp adalah 'phone_number'
        local phone = xPlayer.get('phoneNumber') or xPlayer.get('phone_number')
        if phone == number then
            return xPlayer
        end
    end
    return nil
end

local function GetOnlineStatus(number)
    local Target = GetPlayerByPhone(number)
    local retval = false
    if Target ~= nil then
        retval = true
    end
    return retval
end

local function GenerateMailId()
    return math.random(111111, 999999)
end

local function escape_sqli(source)
    local replacements = {
        ['"'] = '\\"',
        ["'"] = "\\'"
    }
    return source:gsub("['\"]", replacements)
end

function QBPhone.AddMentionedTweet(identifier, TweetData)
    if MentionedTweets[identifier] == nil then
        MentionedTweets[identifier] = {}
    end
    MentionedTweets[identifier][#MentionedTweets[identifier] + 1] = TweetData
end

function QBPhone.SetPhoneAlerts(identifier, app, alerts)
    if identifier ~= nil and app ~= nil then
        if AppAlerts[identifier] == nil then
            AppAlerts[identifier] = {}
            if AppAlerts[identifier][app] == nil then
                if alerts == nil then
                    AppAlerts[identifier][app] = 1
                else
                    AppAlerts[identifier][app] = alerts
                end
            end
        else
            if AppAlerts[identifier][app] == nil then
                if alerts == nil then
                    AppAlerts[identifier][app] = 1
                else
                    AppAlerts[identifier][app] = 0
                end
            else
                if alerts == nil then
                    AppAlerts[identifier][app] = AppAlerts[identifier][app] + 1
                else
                    AppAlerts[identifier][app] = AppAlerts[identifier][app] + 0
                end
            end
        end
    end
end

local function SplitStringToArray(string)
    local retval = {}
    for i in string.gmatch(string, '%S+') do
        retval[#retval + 1] = i
    end
    return retval
end

local function GenerateOwnerName()
    -- Nama palsu untuk kendaraan yang tidak dimiliki player
    local names = {
        [1] = { name = 'Bailey Sykes', identifier = 'DSH091G93' },
        [2] = { name = 'Aroush Goodwin', identifier = 'AVH09M193' },
        -- ... (Anda bisa menambahkan list nama lainnya di sini)
        [3] = { name = 'Jake Kumar', identifier = 'AKA420609' },
    }
    return names[math.random(1, #names)]
end

local function sendNewMailToOffline(identifier, mailData)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if xPlayer then
        local src = xPlayer.source
        local buttonJson = mailData.button and json.encode(mailData.button) or nil
        
        if buttonJson then
             MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { xPlayer.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, buttonJson })
        else
             MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { xPlayer.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
        end

        TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        
        SetTimeout(200, function()
            local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { xPlayer.identifier })
            if mails[1] ~= nil then
                for k, _ in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    else
        local buttonJson = mailData.button and json.encode(mailData.button) or nil
        if buttonJson then
             MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, buttonJson })
        else
             MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
        end
    end
end
exports('sendNewMailToOffline', sendNewMailToOffline)

-- Callbacks

ESX.RegisterServerCallback("qb-phone:server:GetInvoices", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE identifier = ?', { xPlayer.identifier })
        for _, v in pairs(invoices) do
            local senderPly = ESX.GetPlayerFromIdentifier(v.sender) -- v.sender di database harus identifier pengirim
            if senderPly ~= nil then
                v.number = senderPly.get('phoneNumber')
            else
                local res = MySQL.query.await('SELECT phone_number FROM users WHERE identifier = ?', { v.sender })
                if res[1] ~= nil then
                    v.number = res[1].phone_number
                else
                    v.number = nil
                end
            end
        end
        cb(invoices)
        return
    end
    cb({})
end)

ESX.RegisterServerCallback('qb-phone:server:GetCallState', function(_, cb, ContactData)
    local xPlayer = GetPlayerByPhone(ContactData.number)
    if xPlayer ~= nil then
        if Calls[xPlayer.identifier] ~= nil then
            if Calls[xPlayer.identifier].inCall then
                cb(false, true)
            else
                cb(true, true)
            end
        else
            cb(true, true)
        end
    else
        cb(false, false)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:GetPhoneData', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer ~= nil then
        local PhoneData = {
            Applications = {},
            PlayerContacts = {},
            MentionedTweets = {},
            Chats = {},
            Hashtags = {},
            Garage = {},
            Mails = {},
            Adverts = {},
            CryptoTransactions = {},
            Tweets = {},
            Images = {},
            InstalledApps = {} -- ESX tidak punya metadata untuk installed apps secara default
        }
        PhoneData.Adverts = Adverts

        local result = MySQL.query.await('SELECT * FROM player_contacts WHERE identifier = ? ORDER BY name ASC', { xPlayer.identifier })
        if result[1] ~= nil then
            for _, v in pairs(result) do
                v.status = GetOnlineStatus(v.number)
            end
            PhoneData.PlayerContacts = result
        end

        local garageresult = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', { xPlayer.identifier })
        if garageresult[1] ~= nil then
            PhoneData.Garage = garageresult
        end

        local messages = MySQL.query.await('SELECT * FROM phone_messages WHERE identifier = ?', { xPlayer.identifier })
        if messages ~= nil and next(messages) ~= nil then
            PhoneData.Chats = messages
        end

        if AppAlerts[xPlayer.identifier] ~= nil then
            PhoneData.Applications = AppAlerts[xPlayer.identifier]
        end

        if MentionedTweets[xPlayer.identifier] ~= nil then
            PhoneData.MentionedTweets = MentionedTweets[xPlayer.identifier]
        end

        if Hashtags ~= nil and next(Hashtags) ~= nil then
            PhoneData.Hashtags = Hashtags
        end

        local Tweets = MySQL.query.await('SELECT * FROM phone_tweets WHERE `date` > NOW() - INTERVAL ? hour', { 48 }) -- Config.TweetDuration diganti angka manual atau pastikan Config ada

        if Tweets ~= nil and next(Tweets) ~= nil then
            PhoneData.Tweets = Tweets
            TWData = Tweets
        end

        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { xPlayer.identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
            PhoneData.Mails = mails
        end

        local transactions = MySQL.query.await('SELECT * FROM crypto_transactions WHERE identifier = ? ORDER BY `date` ASC', { xPlayer.identifier })
        if transactions[1] ~= nil then
            for _, v in pairs(transactions) do
                PhoneData.CryptoTransactions[#PhoneData.CryptoTransactions + 1] = {
                    TransactionTitle = v.title,
                    TransactionMessage = v.message
                }
            end
        end
        
        local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE identifier = ? ORDER BY `date` DESC', { xPlayer.identifier })
        if images ~= nil and next(images) ~= nil then
            PhoneData.Images = images
        end
        cb(PhoneData)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:PayInvoice', function(source, cb, society, amount, invoiceId, sendercitizenid)
    local xPlayer = ESX.GetPlayerFromId(source)
    local SenderPly = ESX.GetPlayerFromIdentifier(sendercitizenid)
    local invoiceMailData = nil

    if xPlayer then
        local exists = MySQL.query.await('select count(1) as count FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, xPlayer.identifier })

        if exists[1] and exists[1]["count"] == 1 then
            -- Logika billing society/komisi bisa disesuaikan dengan esx_billing / esx_addonaccount
            local billingCommission = 0.10 -- Contoh 10%
            
            if SenderPly then
                local commission = math.floor(amount * billingCommission)
                SenderPly.addAccountMoney('bank', commission)
                invoiceMailData = {
                    sender = 'Billing Department',
                    subject = 'Commission Received',
                    message = string.format('You received a commission check of $%s when %s %s paid a bill of $%s.', commission, xPlayer.getName(), "", amount)
                }
            end

            -- Pembayaran
            if xPlayer.getAccount('bank').money >= amount then
                xPlayer.removeAccountMoney('bank', amount)
                MySQL.query('DELETE FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, xPlayer.identifier })
                
                if invoiceMailData then
                    exports['qb-phone']:sendNewMailToOffline(sendercitizenid, invoiceMailData)
                end
                
                TriggerEvent("qb-phone:server:paidInvoice", source, invoiceId)
                
                -- Tambah uang ke society (Memerlukan esx_addonaccount)
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..society, function(account)
                    if account then
                        account.addMoney(amount)
                    end
                end)
                
                cb(true)
                return
            end
        end
    end
    cb(false)
end)

ESX.RegisterServerCallback('qb-phone:server:DeclineInvoice', function(source, cb, _, _, invoiceId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local exists = MySQL.query.await('select count(1) as count FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, xPlayer.identifier })

        if exists[1] and exists[1]["count"] == 1 then
            TriggerEvent("qb-phone:server:declinedInvoice", source, invoiceId)
            MySQL.query('DELETE FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, xPlayer.identifier })
            cb(true)
            return
        end
    end
    cb(false)
end)

ESX.RegisterServerCallback('qb-phone:server:GetContactPictures', function(_, cb, Chats)
    for _, v in pairs(Chats) do
        local query = v.number
        -- Asumsi kolom phone_number di table users
        local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE phone_number = ?', { query })
        if result[1] ~= nil then
            v.picture = 'default' -- ESX default jarang menyimpan foto profil di DB users, set default atau tambah kolom
        end
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetContactPicture', function(_, cb, Chat)
    -- ESX Logic simplified
    Chat.picture = 'default'
    SetTimeout(100, function()
        cb(Chat)
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetPicture', function(_, cb, number)
    -- ESX Logic simplified
    cb('default')
end)

ESX.RegisterServerCallback('qb-phone:server:FetchResult', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local query = 'SELECT * FROM `users` WHERE `identifier` = "' .. search .. '" OR `firstname` LIKE "%' .. search .. '%" OR `lastname` LIKE "%' .. search .. '%"'
    
    local result = MySQL.query.await(query)
    if result[1] ~= nil then
        for _, v in pairs(result) do
            searchData[#searchData + 1] = {
                identifier = v.identifier,
                firstname = v.firstname,
                lastname = v.lastname,
                birthdate = v.dateofbirth, -- Pastikan kolom ini ada di users
                phone = v.phone_number,
                gender = v.sex,
                driverlicense = true, -- Simplified
                appartmentdata = {} -- ESX biasanya menggunakan script properti terpisah
            }
        end
        cb(searchData)
    else
        cb(nil)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:GetVehicleSearchResults', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local query = '%' .. search .. '%'
    -- Asumsi table vehicles adalah owned_vehicles
    local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate LIKE ? OR owner = ?', { query, search })
    if result[1] ~= nil then
        for k, _ in pairs(result) do
            local player = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', { result[k].owner })
            if player[1] ~= nil then
                local vehicleModel = "Vehicle" -- Perlu script tambahan untuk nama asli kendaraan
                searchData[#searchData + 1] = {
                    plate = result[k].plate,
                    status = true,
                    owner = player[1].firstname .. ' ' .. player[1].lastname,
                    citizenid = result[k].owner,
                    label = vehicleModel
                }
            end
        end
    end
    cb(searchData)
end)

ESX.RegisterServerCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData
    if plate ~= nil then
        local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ?', { plate })
        if result[1] ~= nil then
            local player = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', { result[1].owner })
            if player[1] then
                vehicleData = {
                    plate = plate,
                    status = true,
                    owner = player[1].firstname .. ' ' .. player[1].lastname,
                    citizenid = result[1].owner
                }
            end
        else
            -- Plat palsu / NPC
            local ownerInfo = GenerateOwnerName()
            vehicleData = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.identifier
            }
        end
        cb(vehicleData)
    else
        TriggerClientEvent('esx:showNotification', src, 'No Vehicle Nearby')
        cb(nil)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:HasPhone', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        local HasPhone = xPlayer.getInventoryItem('phone')
        if HasPhone and HasPhone.count > 0 then
            cb(true)
        else
            cb(false)
        end
    end
end)

ESX.RegisterServerCallback('qb-phone:server:CanTransferMoney', function(source, cb, amount, iban)
    -- IBAN di sini diasumsikan sebagai nomor telepon penerima atau identifier rekening
    local newAmount = tonumber(amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getAccount('bank').money >= newAmount then
        -- Mencari penerima berdasarkan IBAN (dianggap phone_number di konversi ini)
        local query = iban
        local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ?', { query })
        
        if result[1] ~= nil then
            local xReceiver = ESX.GetPlayerFromIdentifier(result[1].identifier)
            xPlayer.removeAccountMoney('bank', newAmount)
            
            if xReceiver then
                xReceiver.addAccountMoney('bank', newAmount)
            else
                -- Update database jika offline
                MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', { newAmount, result[1].identifier }) -- Perhatikan kolom 'bank' mungkin berbeda tergantung versi ESX (users.bank atau table accounts)
            end
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentLawyers', function(source, cb)
    local Lawyers = {}
    local xPlayers = ESX.GetExtendedPlayers('job', 'lawyer')
    for _, xPlayer in pairs(xPlayers) do
        Lawyers[#Lawyers + 1] = {
            name = xPlayer.getName(),
            phone = xPlayer.get('phoneNumber'),
            typejob = xPlayer.job.name
        }
    end
    cb(Lawyers)
end)

ESX.RegisterServerCallback('qb-phone:server:GetWebhook', function(_, cb)
    if WebHook ~= '' then
        cb(WebHook)
    else
        print('^1Set your webhook to ensure that your camera will work!!!!!!^0')
        cb(nil)
    end
end)

ESX.RegisterServerCallback('qb-phone:server:UploadToFivemerr', function(source, cb)
    local src = source
    if Config.Fivemerr == true and FivemerrApiToken == '' then
        print("^1--- Fivemerr is enabled but no API token has been specified. ---^7")
        return cb(nil)
    end

    exports['screenshot-basic']:requestClientScreenshot(src, {
        encoding = 'png'
    }, function(err, data)
        if err then return cb(nil) end
        PerformHttpRequest(WebHook, function(status, response)
            if status ~= 200 then
                print("^1--- ERROR UPLOADING IMAGE: " .. status .. " ---^7")
                cb(nil)
            end
            cb(response)
        end, "POST", json.encode({ data = data }), {
            ['Authorization'] = FivemerrApiToken,
            ['Content-Type'] = 'application/json'
        })
    end)
end)

-- Events

RegisterNetEvent('qb-phone:server:AddAdvert', function(msg, url)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    
    local advertData = {
        message = msg,
        name = '@' .. xPlayer.getName(),
        number = xPlayer.get('phoneNumber'),
        url = url
    }

    if Adverts[identifier] ~= nil then
        Adverts[identifier] = advertData
    else
        Adverts[identifier] = advertData
    end
    
    TriggerClientEvent('qb-phone:client:UpdateAdverts', -1, Adverts, '@' .. xPlayer.getName())
end)

RegisterNetEvent('qb-phone:server:DeleteAdvert', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    Adverts[xPlayer.identifier] = nil
    TriggerClientEvent('qb-phone:client:UpdateAdvertsDel', -1, Adverts)
end)

RegisterNetEvent('qb-phone:server:SetCallState', function(bool)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if Calls[xPlayer.identifier] ~= nil then
        Calls[xPlayer.identifier].inCall = bool
    else
        Calls[xPlayer.identifier] = {}
        Calls[xPlayer.identifier].inCall = bool
    end
end)

RegisterNetEvent('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.query('DELETE FROM player_mails WHERE mailid = ? AND identifier = ?', { MailId, xPlayer.identifier })
    SetTimeout(100, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { xPlayer.identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:sendNewMail', function(mailData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local buttonJson = mailData.button and json.encode(mailData.button) or nil
    
    if buttonJson then
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { xPlayer.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, buttonJson })
    else
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { xPlayer.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
    end

    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` DESC', { xPlayer.identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.update('UPDATE player_mails SET button = ? WHERE mailid = ? AND identifier = ?', { '', mailId, xPlayer.identifier })
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { xPlayer.identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:MentionedPlayer', function(firstName, lastName, TweetMessage)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        -- Mendapatkan nama bisa bervariasi tergantung ESX version, ini cara umum ambil dari DB/Cache
        local plyName = xPlayer.getName()
        local tweetTargetName = firstName .. ' ' .. lastName
        
        if plyName == tweetTargetName then
             QBPhone.SetPhoneAlerts(xPlayer.identifier, 'twitter')
             QBPhone.AddMentionedTweet(xPlayer.identifier, TweetMessage)
             TriggerClientEvent('qb-phone:client:GetMentioned', xPlayer.source, TweetMessage, AppAlerts[xPlayer.identifier]['twitter'])
        end
    end
end)

RegisterNetEvent('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local Target = GetPlayerByPhone(TargetData.number)
    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.source, xPlayer.get('phoneNumber'), CallId, AnonymousCall)
    end
end)

RegisterNetEvent('qb-phone:server:BillingEmail', function(data, paid)
    local xPlayers = ESX.GetExtendedPlayers('job', data.society)
    local src = source
    local payer = ESX.GetPlayerFromId(src)
    local payerName = payer.getName()

    for _, target in pairs(xPlayers) do
        TriggerClientEvent('qb-phone:client:BillingEmail', target.source, data, paid, payerName)
    end
end)

RegisterNetEvent('qb-phone:server:UpdateHashtags', function(Handle, messageData)
    if Hashtags[Handle] ~= nil and next(Hashtags[Handle]) ~= nil then
        Hashtags[Handle].messages[#Hashtags[Handle].messages + 1] = messageData
    else
        Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        Hashtags[Handle].messages[#Hashtags[Handle].messages + 1] = messageData
    end
    TriggerClientEvent('qb-phone:client:UpdateHashtags', -1, Handle, messageData)
end)

RegisterNetEvent('qb-phone:server:SetPhoneAlerts', function(app, alerts)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    QBPhone.SetPhoneAlerts(xPlayer.identifier, app, alerts)
end)

RegisterNetEvent('qb-phone:server:DeleteTweet', function(tweetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local delete = false
    local TID = tweetId
    local Data = MySQL.scalar.await('SELECT citizenid FROM phone_tweets WHERE tweetId = ?', { TID })
    
    -- Perhatikan: citizenid di table tweets tetap citizenid (atau identifier)
    if Data == xPlayer.identifier then
        MySQL.query.await('DELETE FROM phone_tweets WHERE tweetId = ?', { TID })
        delete = true
    end

    if delete then
        for k, _ in pairs(TWData) do
            if TWData[k].tweetId == TID then
                TWData = nil
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateTweets', -1, TWData, nil, true)
    end
end)

RegisterNetEvent('qb-phone:server:UpdateTweets', function(NewTweets, TweetData)
    local src = source
    -- TweetData.citizenid diisi identifier dari client side (sesuaikan client.lua)
    MySQL.insert('INSERT INTO phone_tweets (citizenid, firstName, lastName, message, date, url, picture, tweetid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        TweetData.citizenid,
        TweetData.firstName,
        TweetData.lastName,
        TweetData.message,
        TweetData.time,
        TweetData.url:gsub('[%<>\"()\' $]', ''),
        TweetData.picture:gsub('[%<>\"()\' $]', ''),
        TweetData.tweetId
    })
    TriggerClientEvent('qb-phone:client:UpdateTweets', -1, src, NewTweets, TweetData, false)
end)

RegisterNetEvent('qb-phone:server:TransferMoney', function(iban, amount)
    local src = source
    local sender = ESX.GetPlayerFromId(src)
    local amount = tonumber(amount)

    -- IBAN dianggap nomor telepon penerima
    local query = iban
    local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ?', { query })
    
    if result[1] ~= nil then
        local receiver = ESX.GetPlayerFromIdentifier(result[1].identifier)
        
        sender.removeAccountMoney('bank', amount)
        
        if receiver ~= nil then
            receiver.addAccountMoney('bank', amount)
            local PhoneItem = receiver.getInventoryItem('phone')
            
            if PhoneItem and PhoneItem.count > 0 then
                 TriggerClientEvent('qb-phone:client:TransferMoney', receiver.source, amount, receiver.getAccount('bank').money)
            end
        else
            -- Offline transfer (update DB users/accounts)
            MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', { amount, result[1].identifier })
        end
    else
        TriggerClientEvent('esx:showNotification', src, "This account number doesn't exist!")
    end
end)

RegisterNetEvent('qb-phone:server:EditContact', function(newName, newNumber, newIban, oldName, oldNumber, _)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.update(
        'UPDATE player_contacts SET name = ?, number = ?, iban = ? WHERE identifier = ? AND name = ? AND number = ?',
        { newName, newNumber, newIban, xPlayer.identifier, oldName, oldNumber })
end)

RegisterNetEvent('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.query('DELETE FROM player_contacts WHERE name = ? AND number = ? AND identifier = ?',
        { Name, Number, xPlayer.identifier })
end)

RegisterNetEvent('qb-phone:server:AddNewContact', function(name, number, iban)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.insert('INSERT INTO player_contacts (identifier, name, number, iban) VALUES (?, ?, ?, ?)', { xPlayer.identifier, tostring(name), tostring(number), tostring(iban) })
end)

RegisterNetEvent('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, _)
    local src = source
    local SenderData = ESX.GetPlayerFromId(src)
    local SenderNumber = SenderData.get('phoneNumber')
    
    -- Mencari Identifier Penerima berdasarkan Nomor HP
    local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ?', { ChatNumber })
    
    if result[1] ~= nil then
        local TargetIdentifier = result[1].identifier
        local TargetData = ESX.GetPlayerFromIdentifier(TargetIdentifier)
        
        -- Logic update/insert DB disesuaikan dengan Identifier
        local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE identifier = ? AND number = ?', { SenderData.identifier, ChatNumber })
        
        if Chat[1] ~= nil then
             -- Update for target
             MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), TargetIdentifier, SenderNumber })
             -- Update for sender
             MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), SenderData.identifier, ChatNumber })
             
             if TargetData then
                 TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.source, ChatMessages, SenderNumber, false)
             end
        else
             -- Insert
             MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { TargetIdentifier, SenderNumber, json.encode(ChatMessages) })
             MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { SenderData.identifier, ChatNumber, json.encode(ChatMessages) })
             
             if TargetData then
                 TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.source, ChatMessages, SenderNumber, true)
             end
        end
    end
end)

RegisterNetEvent('qb-phone:server:AddRecentCall', function(type, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local Hour = os.date('%H')
    local Minute = os.date('%M')
    local label = Hour .. ':' .. Minute
    
    TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)
    
    local Trgt = GetPlayerByPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.source, {
            name = xPlayer.getName(),
            number = xPlayer.get('phoneNumber'),
            anonymous = data.anonymous
        }, label, 'outgoing')
    end
end)

RegisterNetEvent('qb-phone:server:CancelCall', function(ContactData)
    local xPlayer = GetPlayerByPhone(ContactData.TargetData.number)
    if xPlayer ~= nil then
        TriggerClientEvent('qb-phone:client:CancelCall', xPlayer.source)
    end
end)

RegisterNetEvent('qb-phone:server:AnswerCall', function(CallData)
    local xPlayer = GetPlayerByPhone(CallData.TargetData.number)
    if xPlayer ~= nil then
        TriggerClientEvent('qb-phone:client:AnswerCall', xPlayer.source)
    end
end)

RegisterNetEvent('qb-phone:server:SaveMetaData', function(MData)
    -- ESX tidak menyimpan metadata phone di users, abaikan atau implementasikan custom column
    -- local src = source
    -- local xPlayer = ESX.GetPlayerFromId(src)
    -- Custom Implementation Required
end)

RegisterNetEvent('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local SuggestionData = {
        name = {
            [1] = xPlayer.get('firstName'),
            [2] = xPlayer.get('lastName')
        },
        number = xPlayer.get('phoneNumber'),
        bank = xPlayer.get('phoneNumber') -- ESX biasanya tidak punya IBAN terpisah di charinfo
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
end)

RegisterNetEvent('qb-phone:server:AddTransaction', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.insert('INSERT INTO crypto_transactions (identifier, title, message) VALUES (?, ?, ?)', {
        xPlayer.identifier,
        data.TransactionTitle,
        data.TransactionMessage
    })
end)

RegisterNetEvent('qb-phone:server:InstallApplication', function(ApplicationData)
    -- ESX Default: Tidak support install apps via metadata
end)

RegisterNetEvent('qb-phone:server:RemoveInstallation', function(App)
    -- ESX Default: Tidak support remove apps via metadata
end)

RegisterNetEvent('qb-phone:server:addImageToGallery', function(image)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.insert('INSERT INTO phone_gallery (`identifier`, `image`) VALUES (?, ?)', { xPlayer.identifier, image })
end)

RegisterNetEvent('qb-phone:server:getImageFromGallery', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE identifier = ? ORDER BY `date` DESC', { xPlayer.identifier })
    TriggerClientEvent('qb-phone:refreshImages', src, images)
end)

RegisterNetEvent('qb-phone:server:RemoveImageFromGallery', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local image = data.image
    MySQL.query('DELETE FROM phone_gallery WHERE identifier = ? AND image = ?', { xPlayer.identifier, image })
end)

RegisterNetEvent('qb-phone:server:sendPing', function(data)
    local src = source
    if src == data then
        TriggerClientEvent('esx:showNotification', src, 'You cannot ping yourself')
    end
end)

-- Command (Bill)
-- ESX biasanya menggunakan esx_billing untuk ini, tapi ini konversi manualnya

RegisterCommand('bill', function(source, args)
    local biller = ESX.GetPlayerFromId(source)
    local billed = ESX.GetPlayerFromId(tonumber(args[1]))
    local amount = tonumber(args[2])
    
    if biller.job.name == 'police' or biller.job.name == 'ambulance' or biller.job.name == 'mechanic' then
        if billed ~= nil then
            if biller.identifier ~= billed.identifier then
                if amount and amount > 0 then
                    -- Insert ke database phone_invoices
                    MySQL.insert(
                        'INSERT INTO phone_invoices (identifier, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
                        { billed.identifier, amount, biller.job.name,
                            biller.getName(), biller.identifier })
                    
                    TriggerClientEvent('qb-phone:RefreshPhone', billed.source)
                    TriggerClientEvent('esx:showNotification', source, 'Invoice Successfully Sent')
                    TriggerClientEvent('esx:showNotification', billed.source, 'New Invoice Received')
                else
                    TriggerClientEvent('esx:showNotification', source, 'Must Be A Valid Amount Above 0')
                end
            else
                TriggerClientEvent('esx:showNotification', source, 'You Cannot Bill Yourself')
            end
        else
            TriggerClientEvent('esx:showNotification', source, 'Player Not Online')
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'No Access')
    end
end)

-- =====================================================
-- PHONE NUMBER GENERATOR (SOLUSI AUTO GENERATE)
-- Tambahkan ini di bagian paling bawah server/main.lua
-- =====================================================

local function GenerateUniquePhoneNumber()
    local running = true
    local phone = nil
    while running do
        -- Format nomor HP (Contoh: 0812345678)
        local rand = math.random(10000000, 99999999)
        phone = "08" .. rand
        
        -- Cek apakah nomor sudah dipakai orang lain
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM users WHERE phone_number = ?', { phone })
        if count == 0 then
            running = false
        end
    end
    return phone
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(player, xPlayer, isNew)
    -- Ambil nomor hp saat ini
    local currentNum = xPlayer.get('phoneNumber')

    -- Jika nomor tidak ada (nil) atau kosong ('')
    if currentNum == nil or currentNum == '' then
        print('[INFO] Player ' .. xPlayer.getName() .. ' tidak punya nomor HP. Membuat nomor baru...')
        
        local newNum = GenerateUniquePhoneNumber()
        
        -- 1. Simpan ke Database
        MySQL.update('UPDATE users SET phone_number = ? WHERE identifier = ?', { newNum, xPlayer.identifier }, function(affectedRows)
            if affectedRows > 0 then
                -- 2. Update data pemain yang sedang online agar tidak perlu relog
                xPlayer.set('phoneNumber', newNum)
                print('[SUCCESS] Nomor HP baru dibuat untuk ' .. xPlayer.getName() .. ': ' .. newNum)
            end
        end)
    end
end)