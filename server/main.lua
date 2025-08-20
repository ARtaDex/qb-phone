ESX = exports['es_extended']:getSharedObject()
local QBPhone = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local GeneratedPlates = {}
local WebHook = ''
local FivemerrApiToken = ''
local bannedCharacters = { '%', '$', ';' }
local TWData = {}

-- Functions

local function GetOnlineStatus(number)
    local Target = ESX.GetPlayerFromPhone(number)
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
    local names = {
        [1] = { name = 'Bailey Sykes', identifier = 'DSH091G93' },
        [2] = { name = 'Aroush Goodwin', identifier = 'AVH09M193' },
        [3] = { name = 'Tom Warren', identifier = 'DVH091T93' },
        [4] = { name = 'Abdallah Friedman', identifier = 'GZP091G93' },
        [5] = { name = 'Lavinia Powell', identifier = 'DRH09Z193' },
        [6] = { name = 'Andrew Delarosa', identifier = 'KGV091J93' },
        [7] = { name = 'Skye Cardenas', identifier = 'ODF09S193' },
        [8] = { name = 'Amelia-Mae Walter', identifier = 'KSD0919H3' },
        [9] = { name = 'Elisha Cote', identifier = 'NDX091D93' },
        [10] = { name = 'Janice Rhodes', identifier = 'ZAL0919X3' },
        [11] = { name = 'Justin Harris', identifier = 'ZAK09D193' },
        [12] = { name = 'Montel Graves', identifier = 'POL09F193' },
        [13] = { name = 'Benjamin Zavala', identifier = 'TEW0J9193' },
        [14] = { name = 'Mia Willis', identifier = 'YOO09H193' },
        [15] = { name = 'Jacques Schmitt', identifier = 'QBC091H93' },
        [16] = { name = 'Mert Simmonds', identifier = 'YDN091H93' },
        [17] = { name = 'Rickie Browne', identifier = 'PJD09D193' },
        [18] = { name = 'Deacon Stanley', identifier = 'RND091D93' },
        [19] = { name = 'Daisy Fraser', identifier = 'QWE091A93' },
        [20] = { name = 'Kitty Walters', identifier = 'KJH0919M3' },
        [21] = { name = 'Jareth Fernandez', identifier = 'ZXC09D193' },
        [22] = { name = 'Meredith Calhoun', identifier = 'XYZ0919C3' },
        [23] = { name = 'Teagan Mckay', identifier = 'ZYX0919F3' },
        [24] = { name = 'Kurt Bain', identifier = 'IOP091O93' },
        [25] = { name = 'Burt Kain', identifier = 'PIO091R93' },
        [26] = { name = 'Joanna Huff', identifier = 'LEK091X93' },
        [27] = { name = 'Carrie-Ann Pineda', identifier = 'ALG091Y93' },
        [28] = { name = 'Gracie-Mai Mcghee', identifier = 'YUR09E193' },
        [29] = { name = 'Robyn Boone', identifier = 'SOM091W93' },
        [30] = { name = 'Aliya William', identifier = 'KAS009193' },
        [31] = { name = 'Rohit West', identifier = 'SOK091093' },
        [32] = { name = 'Skylar Archer', identifier = 'LOK091093' },
        [33] = { name = 'Jake Kumar', identifier = 'AKA420609' },
    }
    return names[math.random(1, #names)]
end


local function sendNewMailToOffline(identifier, mailData)
    -- ESX version: get player from database if not online
    local Player = ESX.GetPlayerFromIdentifier(identifier)
    if not Player then
        -- Try to get from DB if not online
        local result = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { identifier })
        if result and result[1] then
            Player = {
                PlayerData = {
                    identifier = result[1].identifier,
                    source = nil -- offline, no source
                }
            }
        else
            Player = nil
        end
    else
        Player = {
            PlayerData = {
                identifier = Player.identifier,
                source = Player.source
            }
        }
    end
    if Player then
        local src = Player.PlayerData.source
        if mailData.button == nil then
            MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { Player.PlayerData.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        else
            MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { Player.PlayerData.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button) })
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        end
        SetTimeout(200, function()
            local mails = MySQL.query.await(
                'SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { Player.PlayerData.identifier })
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
        if mailData.button == nil then
            MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
        else
            MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button) })
        end
    end
end
exports('sendNewMailToOffline', sendNewMailToOffline)
-- Callbacks

QBCore.Functions.CreateCallback("qb-phone:server:GetInvoices", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE identifier = ?', { Player.PlayerData.identifier })
        for _, v in pairs(invoices) do
            local Ply = QBCore.Functions.GetPlayerByidentifier(v.sender)
            if Ply ~= nil then
                v.number = Ply.PlayerData.charinfo.phone
            else
                local res = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { v.sender })
                if res[1] ~= nil then
                    res[1].charinfo = json.decode(res[1].charinfo)
                    v.number = res[1].charinfo.phone
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

QBCore.Functions.CreateCallback('qb-phone:server:GetCallState', function(_, cb, ContactData)
    local Target = QBCore.Functions.GetPlayerByPhone(ContactData.number)
    if Target ~= nil then
        if Calls[Target.PlayerData.identifier] ~= nil then
            if Calls[Target.PlayerData.identifier].inCall then
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

QBCore.Functions.CreateCallback('qb-phone:server:GetPhoneData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
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
            InstalledApps = Player.PlayerData.metadata['phonedata'].InstalledApps
        }
        PhoneData.Adverts = Adverts

        local result = MySQL.query.await('SELECT * FROM player_contacts WHERE identifier = ? ORDER BY name ASC', { Player.PlayerData.identifier })
        if result[1] ~= nil then
            for _, v in pairs(result) do
                v.status = GetOnlineStatus(v.number)
            end

            PhoneData.PlayerContacts = result
        end

        local garageresult = MySQL.query.await('SELECT * FROM owned_vehicles WHERE identifier = ?', { Player.PlayerData.identifier })
        if garageresult[1] ~= nil then
            PhoneData.Garage = garageresult
        end

        local messages = MySQL.query.await('SELECT * FROM phone_messages WHERE identifier = ?', { Player.PlayerData.identifier })
        if messages ~= nil and next(messages) ~= nil then
            PhoneData.Chats = messages
        end

        if AppAlerts[Player.PlayerData.identifier] ~= nil then
            PhoneData.Applications = AppAlerts[Player.PlayerData.identifier]
        end

        if MentionedTweets[Player.PlayerData.identifier] ~= nil then
            PhoneData.MentionedTweets = MentionedTweets[Player.PlayerData.identifier]
        end

        if Hashtags ~= nil and next(Hashtags) ~= nil then
            PhoneData.Hashtags = Hashtags
        end

        local Tweets = MySQL.query.await('SELECT * FROM phone_tweets WHERE `date` > NOW() - INTERVAL ? hour', { Config.TweetDuration })

        if Tweets ~= nil and next(Tweets) ~= nil then
            PhoneData.Tweets = Tweets
            TWData = Tweets
        end

        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { Player.PlayerData.identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
            PhoneData.Mails = mails
        end

        local transactions = MySQL.query.await('SELECT * FROM crypto_transactions WHERE identifier = ? ORDER BY `date` ASC', { Player.PlayerData.identifier })
        if transactions[1] ~= nil then
            for _, v in pairs(transactions) do
                PhoneData.CryptoTransactions[#PhoneData.CryptoTransactions + 1] = {
                    TransactionTitle = v.title,
                    TransactionMessage = v.message
                }
            end
        end
        local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE identifier = ? ORDER BY `date` DESC', { Player.PlayerData.identifier })
        if images ~= nil and next(images) ~= nil then
            PhoneData.Images = images
        end
        cb(PhoneData)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:PayInvoice', function(source, cb, society, amount, invoiceId, senderidentifier)
    local Ply = QBCore.Functions.GetPlayer(source)
    local SenderPly = QBCore.Functions.GetPlayerByidentifier(senderidentifier)
    local invoiceMailData = nil
    if Ply then
        local exists = MySQL.query.await('select count(1) as count FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, Ply.PlayerData.identifier })

        if exists[1] and exists[1]["count"] == 1 then
            if SenderPly and Config.BillingCommissions[society] then
                local commission = QBCore.Shared.Round(amount * Config.BillingCommissions[society])
                SenderPly.Functions.AddMoney('bank', commission)
                invoiceMailData = {
                    sender = 'Billing Department',
                    subject = 'Commission Received',
                    message = string.format('You received a commission check of $%s when %s %s paid a bill of $%s.', commission, Ply.PlayerData.charinfo.firstname, Ply.PlayerData.charinfo.lastname, amount)
                }
            elseif not SenderPly and Config.BillingCommissions[society] then
                invoiceMailData = {
                    sender = 'Billing Department',
                    subject = 'Bill Paid',
                    message = string.format('%s %s paid a bill of $%s', Ply.PlayerData.charinfo.firstname, Ply.PlayerData.charinfo.lastname, amount)
                }
            end
            if Ply.Functions.RemoveMoney('bank', amount, 'paid-invoice') then
                MySQL.query('DELETE FROM phone_invoices WHERE id = ? and identifier = ?', { invoiceId, Ply.PlayerData.identifier })
                if invoiceMailData then
                    exports['qb-phone']:sendNewMailToOffline(senderidentifier, invoiceMailData)
                end
                TriggerEvent("qb-phone:server:paidInvoice", source, invoiceId)
                exports['qb-banking']:AddMoney(society, amount, 'Phone invoice')
                cb(true)
                return
            end
        end
    end
    cb(false)
end)

QBCore.Functions.CreateCallback('qb-phone:server:DeclineInvoice', function(source, cb, _, _, invoiceId)
    local Ply = QBCore.Functions.GetPlayer(source)
    if Ply then
        local exists = MySQL.query.await('select count(1) as count FROM phone_invoices WHERE id = ? and identifier = ? and candecline = ?', { invoiceId, Ply.PlayerData.identifier, 1 })

        if exists[1] and exists[1]["count"] == 1 then
            TriggerEvent("qb-phone:server:declinedInvoice", source, invoiceId)
            MySQL.query('DELETE FROM phone_invoices WHERE id = ? and identifier = ? and candecline = ?', { invoiceId, Ply.PlayerData.identifier, 1 })
            cb(true)
            return
        end
    end

    cb(false)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPictures', function(_, cb, Chats)
    for _, v in pairs(Chats) do
        local query = '%' .. v.number .. '%'
        local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
        if result[1] ~= nil then
            local MetaData = json.decode(result[1].metadata)

            if MetaData.phone.profilepicture ~= nil then
                v.picture = MetaData.phone.profilepicture
            else
                v.picture = 'default'
            end
        end
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPicture', function(_, cb, Chat)
    local query = '%' .. Chat.number .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
    local MetaData = json.decode(result[1].metadata)
    if MetaData.phone.profilepicture ~= nil then
        Chat.picture = MetaData.phone.profilepicture
    else
        Chat.picture = 'default'
    end
    SetTimeout(100, function()
        cb(Chat)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPicture', function(_, cb, number)
    local query = '%' .. number .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
    if result[1] ~= nil then
        local Picture = 'default'
        local MetaData = json.decode(result[1].metadata)
        if MetaData.phone.profilepicture ~= nil then
            Picture = MetaData.phone.profilepicture
        end
        cb(Picture)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:FetchResult', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local ApaData = {}
    local query = 'SELECT * FROM `players` WHERE `identifier` = "' .. search .. '"'
    -- Split on " " and check each var individual
    local searchParameters = SplitStringToArray(search)
    -- Construct query dynamicly for individual parm check
    if #searchParameters > 1 then
        query = query .. ' OR `charinfo` LIKE "%' .. searchParameters[1] .. '%"'
        for i = 2, #searchParameters do
            query = query .. ' AND `charinfo` LIKE  "%' .. searchParameters[i] .. '%"'
        end
    else
        query = query .. ' OR `charinfo` LIKE "%' .. search .. '%"'
    end
    local ApartmentData = MySQL.query.await('SELECT * FROM apartments', {})
    for k, v in pairs(ApartmentData) do
        ApaData[v.identifier] = ApartmentData[k]
    end
    local result = MySQL.query.await(query)
    if result[1] ~= nil then
        for _, v in pairs(result) do
            local charinfo = json.decode(v.charinfo)
            local metadata = json.decode(v.metadata)
            local appiepappie = {}
            if ApaData[v.identifier] ~= nil and next(ApaData[v.identifier]) ~= nil then
                appiepappie = ApaData[v.identifier]
            end
            searchData[#searchData + 1] = {
                identifier = v.identifier,
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                birthdate = charinfo.birthdate,
                phone = charinfo.phone,
                nationality = charinfo.nationality,
                gender = charinfo.gender,
                warrant = false,
                driverlicense = metadata['licences']['driver'],
                appartmentdata = appiepappie
            }
        end
        cb(searchData)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetVehicleSearchResults', function(_, cb, search)
    search = escape_sqli(search)
    local searchData = {}
    local query = '%' .. search .. '%'
    local result = MySQL.query.await('SELECT * FROM owned_vehicl WHERE plate LIKE ? OR identifier = ?',
        { query, search })
    if result[1] ~= nil then
        for k, _ in pairs(result) do
            local player = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { result[k].identifier })
            if player[1] ~= nil then
                local charinfo = json.decode(player[1].charinfo)
                local vehicleInfo = QBCore.Shared.Vehicles[result[k].vehicle]
                if vehicleInfo ~= nil then
                    searchData[#searchData + 1] = {
                        plate = result[k].plate,
                        status = true,
                        owner = charinfo.firstname .. ' ' .. charinfo.lastname,
                        identifier = result[k].identifier,
                        label = vehicleInfo['name']
                    }
                else
                    searchData[#searchData + 1] = {
                        plate = result[k].plate,
                        status = true,
                        owner = charinfo.firstname .. ' ' .. charinfo.lastname,
                        identifier = result[k].identifier,
                        label = 'Name not found..'
                    }
                end
            end
        end
    else
        if GeneratedPlates[search] ~= nil then
            searchData[#searchData + 1] = {
                plate = GeneratedPlates[search].plate,
                status = GeneratedPlates[search].status,
                owner = GeneratedPlates[search].owner,
                identifier = GeneratedPlates[search].identifier,
                label = 'Brand unknown..'
            }
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[search] = {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier
            }
            searchData[#searchData + 1] = {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier,
                label = 'Brand unknown..'
            }
        end
    end
    cb(searchData)
end)

QBCore.Functions.CreateCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData
    if plate ~= nil then
        local result = MySQL.query.await('SELECT * FROM owned_vehicl WHERE plate = ?', { plate })
        if result[1] ~= nil then
            local player = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { result[1].identifier })
            local charinfo = json.decode(player[1].charinfo)
            vehicleData = {
                plate = plate,
                status = true,
                owner = charinfo.firstname .. ' ' .. charinfo.lastname,
                identifier = result[1].identifier
            }
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then
            vehicleData = GeneratedPlates[plate]
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[plate] = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier
            }
            vehicleData = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier
            }
        end
        cb(vehicleData)
    else
        TriggerClientEvent('QBCore:Notify', src, 'No Vehicle Nearby', 'error')
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:HasPhone', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player ~= nil then
        local HasPhone = Player.Functions.GetItemByName('phone')
        if HasPhone ~= nil then
            cb(true)
        else
            cb(false)
        end
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:CanTransferMoney', function(source, cb, amount, iban)
    -- strip bad characters from bank transfers
    local newAmount = tostring(amount)
    local newiban = tostring(iban)
    for _, v in pairs(bannedCharacters) do
        newAmount = string.gsub(newAmount, '%' .. v, '')
        newiban = string.gsub(newiban, '%' .. v, '')
    end
    iban = newiban
    amount = tonumber(newAmount)

    local Player = QBCore.Functions.GetPlayer(source)
    if (Player.PlayerData.money.bank - amount) >= 0 then
        local query = '%"account":"' .. iban .. '"%'
        local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
        if result[1] ~= nil then
            local Reciever = QBCore.Functions.GetPlayerByidentifier(result[1].identifier)
            Player.Functions.RemoveMoney('bank', amount)
            if Reciever ~= nil then
                Reciever.Functions.AddMoney('bank', amount)
            else
                local RecieverMoney = json.decode(result[1].money)
                RecieverMoney.bank = (RecieverMoney.bank + amount)
                MySQL.update('UPDATE players SET money = ? WHERE identifier = ?', { json.encode(RecieverMoney), result[1].identifier })
            end
            cb(true)
        else
            cb(false)
        end
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentLawyers', function(_, cb)
    local Lawyers = {}
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.job.name == 'lawyer' or Player.PlayerData.job.name == 'realestate' or
                    Player.PlayerData.job.name == 'mechanic' or Player.PlayerData.job.name == 'taxi' or
                    Player.PlayerData.job.name == 'police' or Player.PlayerData.job.name == 'ambulance') and
                Player.PlayerData.job.onduty then
                Lawyers[#Lawyers + 1] = {
                    name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                    typejob = Player.PlayerData.job.name
                }
            end
        end
    end
    cb(Lawyers)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetWebhook', function(_, cb)
    if WebHook ~= '' then
        cb(WebHook)
    else
        print('Set your webhook to ensure that your camera will work!!!!!! Set this on line 9 of the server sided script!!!!!')
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:UploadToFivemerr', function(source, cb)
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
    local Player = QBCore.Functions.GetPlayer(src)
    local identifier = Player.PlayerData.identifier
    if Adverts[identifier] ~= nil then
        Adverts[identifier].message = msg
        Adverts[identifier].name = '@' .. Player.PlayerData.charinfo.firstname .. '' .. Player.PlayerData.charinfo.lastname
        Adverts[identifier].number = Player.PlayerData.charinfo.phone
        Adverts[identifier].url = url
    else
        Adverts[identifier] = {
            message = msg,
            name = '@' .. Player.PlayerData.charinfo.firstname .. '' .. Player.PlayerData.charinfo.lastname,
            number = Player.PlayerData.charinfo.phone,
            url = url
        }
    end
    TriggerClientEvent('qb-phone:client:UpdateAdverts', -1, Adverts, '@' .. Player.PlayerData.charinfo.firstname .. '' .. Player.PlayerData.charinfo.lastname)
end)

RegisterNetEvent('qb-phone:server:DeleteAdvert', function()
    local Player = QBCore.Functions.GetPlayer(source)
    local identifier = Player.PlayerData.identifier
    Adverts[identifier] = nil
    TriggerClientEvent('qb-phone:client:UpdateAdvertsDel', -1, Adverts)
end)

RegisterNetEvent('qb-phone:server:SetCallState', function(bool)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    if Calls[Ply.PlayerData.identifier] ~= nil then
        Calls[Ply.PlayerData.identifier].inCall = bool
    else
        Calls[Ply.PlayerData.identifier] = {}
        Calls[Ply.PlayerData.identifier].inCall = bool
    end
end)

RegisterNetEvent('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.query('DELETE FROM player_mails WHERE mailid = ? AND identifier = ?', { MailId, Player.PlayerData.identifier })
    SetTimeout(100, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { Player.PlayerData.identifier })
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
    local Player = QBCore.Functions.GetPlayer(src)
    if mailData.button == nil then
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { Player.PlayerData.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
    else
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { Player.PlayerData.identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button) })
    end
    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` DESC',
            { Player.PlayerData.identifier })
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

RegisterNetEvent('qb-phone:server:sendNewEventMail', function(identifier, mailData)
    local Player = QBCore.Functions.GetPlayerByidentifier(identifier)
    if mailData.button == nil then
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0 })
    else
        MySQL.insert('INSERT INTO player_mails (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', { identifier, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button) })
    end
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { identifier })
        if mails[1] ~= nil then
            for k, _ in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = json.decode(mails[k].button)
                end
            end
        end
        TriggerClientEvent('qb-phone:client:UpdateMails', Player.PlayerData.source, mails)
    end)
end)

RegisterNetEvent('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.update('UPDATE player_mails SET button = ? WHERE mailid = ? AND identifier = ?', { '', mailId, Player.PlayerData.identifier })
    SetTimeout(200, function()
        local mails = MySQL.query.await('SELECT * FROM player_mails WHERE identifier = ? ORDER BY `date` ASC', { Player.PlayerData.identifier })
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
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.charinfo.firstname == firstName and Player.PlayerData.charinfo.lastname == lastName) then
                QBPhone.SetPhoneAlerts(Player.PlayerData.identifier, 'twitter')
                QBPhone.AddMentionedTweet(Player.PlayerData.identifier, TweetMessage)
                TriggerClientEvent('qb-phone:client:GetMentioned', Player.PlayerData.source, TweetMessage, AppAlerts[Player.PlayerData.identifier]['twitter'])
            else
                local query1 = '%' .. firstName .. '%'
                local query2 = '%' .. lastName .. '%'
                local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ? AND charinfo LIKE ?', { query1, query2 })
                if result[1] ~= nil then
                    local MentionedTarget = result[1].identifier
                    QBPhone.SetPhoneAlerts(MentionedTarget, 'twitter')
                    QBPhone.AddMentionedTweet(MentionedTarget, TweetMessage)
                end
            end
        end
    end
end)

RegisterNetEvent('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByPhone(TargetData.number)
    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.PlayerData.source, Ply.PlayerData.charinfo.phone, CallId, AnonymousCall)
    end
end)

RegisterNetEvent('qb-phone:server:BillingEmail', function(data, paid)
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local target = QBCore.Functions.GetPlayer(v)
        if target.PlayerData.job.name == data.society then
            if paid then
                local name = '' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.firstname .. ' ' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.lastname .. ''
                TriggerClientEvent('qb-phone:client:BillingEmail', target.PlayerData.source, data, true, name)
            else
                local name = '' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.firstname .. ' ' .. QBCore.Functions.GetPlayer(source).PlayerData.charinfo.lastname .. ''
                TriggerClientEvent('qb-phone:client:BillingEmail', target.PlayerData.source, data, false, name)
            end
        end
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
    local identifier = QBCore.Functions.GetPlayer(src).identifier
    QBPhone.SetPhoneAlerts(identifier, app, alerts)
end)

RegisterNetEvent('qb-phone:server:DeleteTweet', function(tweetId)
    local Player = QBCore.Functions.GetPlayer(source)
    local delete = false
    local TID = tweetId
    local Data = MySQL.scalar.await('SELECT identifier FROM phone_tweets WHERE tweetId = ?', { TID })
    if Data == Player.PlayerData.identifier then
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

    MySQL.insert('INSERT INTO phone_tweets (identifier, firstName, lastName, message, date, url, picture, tweetid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        TweetData.identifier,
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
    local sender = QBCore.Functions.GetPlayer(src)

    local query = '%' .. iban .. '%'
    local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
    if result[1] ~= nil then
        local reciever = QBCore.Functions.GetPlayerByidentifier(result[1].identifier)

        if reciever ~= nil then
            local PhoneItem = reciever.Functions.GetItemByName('phone')
            reciever.Functions.AddMoney('bank', amount, 'phone-transfered-from-' .. sender.PlayerData.identifier)
            sender.Functions.RemoveMoney('bank', amount, 'phone-transfered-to-' .. reciever.PlayerData.identifier)

            if PhoneItem ~= nil then
                TriggerClientEvent('qb-phone:client:TransferMoney', reciever.PlayerData.source, amount,
                    reciever.PlayerData.money.bank)
            end
        else
            local moneyInfo = json.decode(result[1].money)
            moneyInfo.bank = QBCore.Shared.Round(moneyInfo.bank + amount)
            MySQL.update('UPDATE players SET money = ? WHERE identifier = ?',
                { json.encode(moneyInfo), result[1].identifier })
            sender.Functions.RemoveMoney('bank', amount, 'phone-transfered')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "This account number doesn't exist!", 'error')
    end
end)

RegisterNetEvent('qb-phone:server:EditContact', function(newName, newNumber, newIban, oldName, oldNumber, _)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.update(
        'UPDATE player_contacts SET name = ?, number = ?, iban = ? WHERE identifier = ? AND name = ? AND number = ?',
        { newName, newNumber, newIban, Player.PlayerData.identifier, oldName, oldNumber })
end)

RegisterNetEvent('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.query('DELETE FROM player_contacts WHERE name = ? AND number = ? AND identifier = ?',
        { Name, Number, Player.PlayerData.identifier })
end)

RegisterNetEvent('qb-phone:server:AddNewContact', function(name, number, iban)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO player_contacts (identifier, name, number, iban) VALUES (?, ?, ?, ?)', { Player.PlayerData.identifier, tostring(name), tostring(number), tostring(iban) })
end)

RegisterNetEvent('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, _)
    local src = source
    local SenderData = QBCore.Functions.GetPlayer(src)
    local query = '%' .. ChatNumber .. '%'
    local Player = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', { query })
    if Player[1] ~= nil then
        local TargetData = QBCore.Functions.GetPlayerByidentifier(Player[1].identifier)
        if TargetData ~= nil then
            local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE identifier = ? AND number = ?', { SenderData.PlayerData.identifier, ChatNumber })
            if Chat[1] ~= nil then
                -- Update for target
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), TargetData.PlayerData.identifier, SenderData.PlayerData.charinfo.phone })
                -- Update for sender
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), SenderData.PlayerData.identifier, TargetData.PlayerData.charinfo.phone })
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, false)
            else
                -- Insert for target
                MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { TargetData.PlayerData.identifier, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages) })
                -- Insert for sender
                MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { SenderData.PlayerData.identifier, TargetData.PlayerData.charinfo.phone, json.encode(ChatMessages) })
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, true)
            end
        else
            local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE identifier = ? AND number = ?', { SenderData.PlayerData.identifier, ChatNumber })
            if Chat[1] ~= nil then
                -- Update for target
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), Player[1].identifier, SenderData.PlayerData.charinfo.phone })
                -- Update for sender
                Player[1].charinfo = json.decode(Player[1].charinfo)
                MySQL.update('UPDATE phone_messages SET messages = ? WHERE identifier = ? AND number = ?', { json.encode(ChatMessages), SenderData.PlayerData.identifier, Player[1].charinfo.phone })
            else
                -- Insert for target
                MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { Player[1].identifier, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages) })
                -- Insert for sender
                Player[1].charinfo = json.decode(Player[1].charinfo)
                MySQL.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', { SenderData.PlayerData.identifier, Player[1].charinfo.phone, json.encode(ChatMessages) })
            end
        end
    end
end)

RegisterNetEvent('qb-phone:server:AddRecentCall', function(type, data)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Hour = os.date('%H')
    local Minute = os.date('%M')
    local label = Hour .. ':' .. Minute
    TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)
    local Trgt = QBCore.Functions.GetPlayerByPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.PlayerData.source, {
            name = Ply.PlayerData.charinfo.firstname .. ' ' .. Ply.PlayerData.charinfo.lastname,
            number = Ply.PlayerData.charinfo.phone,
            anonymous = data.anonymous
        }, label, 'outgoing')
    end
end)

RegisterNetEvent('qb-phone:server:CancelCall', function(ContactData)
    local Ply = QBCore.Functions.GetPlayerByPhone(ContactData.TargetData.number)
    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:CancelCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:AnswerCall', function(CallData)
    local Ply = QBCore.Functions.GetPlayerByPhone(CallData.TargetData.number)
    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:AnswerCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:SaveMetaData', function(MData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { Player.PlayerData.identifier })
    local MetaData = json.decode(result[1].metadata)
    MetaData.phone = MData
    MySQL.update('UPDATE players SET metadata = ? WHERE identifier = ?',
        { json.encode(MetaData), Player.PlayerData.identifier })
    Player.Functions.SetMetaData('phone', MData)
end)

RegisterNetEvent('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local SuggestionData = {
        name = {
            [1] = Player.PlayerData.charinfo.firstname,
            [2] = Player.PlayerData.charinfo.lastname
        },
        number = Player.PlayerData.charinfo.phone,
        bank = Player.PlayerData.charinfo.account
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
end)

RegisterNetEvent('qb-phone:server:AddTransaction', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO crypto_transactions (identifier, title, message) VALUES (?, ?, ?)', {
        Player.PlayerData.identifier,
        data.TransactionTitle,
        data.TransactionMessage
    })
end)

RegisterNetEvent('qb-phone:server:InstallApplication', function(ApplicationData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata['phonedata'].InstalledApps[ApplicationData.app] = ApplicationData
    Player.Functions.SetMetaData('phonedata', Player.PlayerData.metadata['phonedata'])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterNetEvent('qb-phone:server:RemoveInstallation', function(App)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata['phonedata'].InstalledApps[App] = nil
    Player.Functions.SetMetaData('phonedata', Player.PlayerData.metadata['phonedata'])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterNetEvent('qb-phone:server:addImageToGallery', function(image)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.insert('INSERT INTO phone_gallery (`identifier`, `image`) VALUES (?, ?)', { Player.PlayerData.identifier, image })
end)

RegisterNetEvent('qb-phone:server:getImageFromGallery', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local images = MySQL.query.await('SELECT * FROM phone_gallery WHERE identifier = ? ORDER BY `date` DESC', { Player.PlayerData.identifier })
    TriggerClientEvent('qb-phone:refreshImages', src, images)
end)

RegisterNetEvent('qb-phone:server:RemoveImageFromGallery', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local image = data.image
    MySQL.query('DELETE FROM phone_gallery WHERE identifier = ? AND image = ?', { Player.PlayerData.identifier, image })
end)

RegisterNetEvent('qb-phone:server:sendPing', function(data)
    local src = source
    if src == data then
        TriggerClientEvent('QBCore:Notify', src, 'You cannot ping yourself', 'error')
    end
end)

-- Command

QBCore.Commands.Add('setmetadata', 'Set Player Metadata (God Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if args[1] then
        if args[1] == 'trucker' then
            if args[2] then
                local newrep = Player.PlayerData.metadata['jobrep']
                newrep.trucker = tonumber(args[2])
                Player.Functions.SetMetaData('jobrep', newrep)
            end
        end
    end
end, 'god')

QBCore.Commands.Add('bill', 'Bill A Player', { { name = 'id', help = 'Player ID' }, { name = 'amount', help = 'Fine Amount' } }, false, function(source, args)
    local biller = QBCore.Functions.GetPlayer(source)
    local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local amount = tonumber(args[2])
    if biller.PlayerData.job.name == 'police' or biller.PlayerData.job.name == 'ambulance' or biller.PlayerData.job.name == 'mechanic' then
        if billed ~= nil then
            if biller.PlayerData.identifier ~= billed.PlayerData.identifier then
                if amount and amount > 0 then
                    MySQL.insert(
                        'INSERT INTO phone_invoices (identifier, amount, society, sender, senderidentifier) VALUES (?, ?, ?, ?, ?)',
                        { billed.PlayerData.identifier, amount, biller.PlayerData.job.name,
                            biller.PlayerData.charinfo.firstname, biller.PlayerData.identifier })
                    TriggerClientEvent('qb-phone:RefreshPhone', billed.PlayerData.source)
                    TriggerClientEvent('QBCore:Notify', source, 'Invoice Successfully Sent', 'success')
                    TriggerClientEvent('QBCore:Notify', billed.PlayerData.source, 'New Invoice Received')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Must Be A Valid Amount Above 0', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'You Cannot Bill Yourself', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player Not Online', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'No Access', 'error')
    end
end)

ESX.RegisterServerCallback('esx_phone:server:HasPhone', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasPhone = false

    -- Jika kamu menggunakan inventory ESX default
    for _, item in pairs(xPlayer.getInventory()) do
        if item.name == 'phone' and item.count > 0 then
            hasPhone = true
            break
        end
    end

    cb(hasPhone)
end)
