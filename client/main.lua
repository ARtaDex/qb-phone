local ESX = exports['es_extended']:getSharedObject()
local PlayerJob = {}
local patt = '[?!@#]'
local frontCam = false
PhoneData = {
    MetaData = {},
    isOpen = false,
    PlayerData = nil,
    Contacts = {},
    Tweets = {},
    MentionedTweets = {},
    Hashtags = {},
    Chats = {},
    CallData = {},
    RecentCalls = {},
    Garage = {},
    Mails = {},
    Adverts = {},
    GarageVehicles = {},
    AnimationData = {
        lib = nil,
        anim = nil,
    },
    SuggestedContacts = {},
    CryptoTransactions = {},
    Images = {},
}

-- Functions

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        result[#result + 1] = string.sub(self, from, delim_from - 1)
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    result[#result + 1] = string.sub(self, from)
    return result
end

local function escape_str(s)
    return s
end

local function GenerateTweetId()
    local tweetId = 'TWEET-' .. math.random(11111111, 99999999)
    return tweetId
end

local function IsNumberInContacts(num)
    local retval = num
    for _, v in pairs(PhoneData.Contacts) do
        if num == v.number then
            retval = v.name
        end
    end
    return retval
end

local function CalculateTimeToDisplay()
    local hour = GetClockHours()
    local minute = GetClockMinutes()

    local obj = {}

    if minute <= 9 then
        minute = '0' .. minute
    end

    obj.hour = hour
    obj.minute = minute

    return obj
end

local function GetClosestPlayer()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    return closestPlayer, closestDistance
end

local function GetKeyByDate(Number, Date)
    local retval = nil
    if PhoneData.Chats[Number] ~= nil then
        if PhoneData.Chats[Number].messages ~= nil then
            for key, chat in pairs(PhoneData.Chats[Number].messages) do
                if chat.date == Date then
                    retval = key
                    break
                end
            end
        end
    end
    return retval
end

local function GetKeyByNumber(Number)
    local retval = nil
    if PhoneData.Chats then
        for k, v in pairs(PhoneData.Chats) do
            if v.number == Number then
                retval = k
            end
        end
    end
    return retval
end

local function ReorganizeChats(key)
    local ReorganizedChats = {}
    ReorganizedChats[1] = PhoneData.Chats[key]
    for k, chat in pairs(PhoneData.Chats) do
        if k ~= key then
            ReorganizedChats[#ReorganizedChats + 1] = chat
        end
    end
    PhoneData.Chats = ReorganizedChats
end

local function findVehFromPlateAndLocate(plate)
    local gameVehicles = ESX.Game.GetVehicles()
    for i = 1, #gameVehicles do
        local vehicle = gameVehicles[i]
        if DoesEntityExist(vehicle) then
            local vehPlate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
            if vehPlate == plate then
                local vehCoords = GetEntityCoords(vehicle)
                SetNewWaypoint(vehCoords.x, vehCoords.y)
                return true
            end
        end
    end
end

local function DisableDisplayControlActions()
    -- 1. MATIKAN SERANGAN (Agar tidak memukul saat klik aplikasi)
    DisableControlAction(0, 24, true) -- Attack (Klik Kiri)
    DisableControlAction(0, 257, true) -- Attack 2
    DisableControlAction(0, 140, true) -- Melee Attack Light
    DisableControlAction(0, 141, true) -- Melee Attack Heavy
    DisableControlAction(0, 142, true) -- Melee Attack Alternate
    DisableControlAction(0, 263, true) -- Melee Attack 1
    DisableControlAction(0, 264, true) -- Melee Attack 2

    -- 2. MATIKAN WEAPON WHEEL & SCROLL (Agar senjata tidak ganti)
    DisableControlAction(0, 37, true) -- Select Weapon (Tab)
    DisableControlAction(0, 12, true) -- Weapon Wheel Up (Scroll)
    DisableControlAction(0, 13, true) -- Weapon Wheel Down (Scroll)
    DisableControlAction(0, 14, true) -- Weapon Wheel Next (Scroll)
    DisableControlAction(0, 15, true) -- Weapon Wheel Prev (Scroll)
    DisableControlAction(0, 261, true) -- Prev Weapon
    DisableControlAction(0, 262, true) -- Next Weapon

    -- 3. MATIKAN AIM & RELOAD
    DisableControlAction(0, 25, true) -- Aim (Klik Kanan)
    DisableControlAction(0, 45, true) -- Reload (R)

    -- 4. MATIKAN GERAKAN FISIK LAINNYA
    DisableControlAction(0, 22, true) -- Jump (Spasi) - Opsional, matikan jika ingin
    DisableControlAction(0, 44, true) -- Cover (Q)
    DisableControlAction(0, 143, true) -- Melee Block (R)
    
    -- 5. MATIKAN KAMERA (Agar mouse tidak memutar kamera saat gerak kursor HP)
    DisableControlAction(0, 1, true) -- Look Left/Right
    DisableControlAction(0, 2, true) -- Look Up/Down

    -- 6. MATIKAN TOMBOL HP & PAUSE
    DisableControlAction(0, 199, true) -- Pause Menu (P)
    DisableControlAction(0, 200, true) -- Pause Menu (ESC)
    DisableControlAction(0, 245, true) -- disable chat
    DisableControlAction(0, 1, true)   -- disable mouse look
    DisableControlAction(0, 2, true)   -- disable mouse look
    DisableControlAction(0, 3, true)   -- disable mouse look
    DisableControlAction(0, 4, true)   -- disable mouse look
    DisableControlAction(0, 5, true)   -- disable mouse look
    DisableControlAction(0, 6, true)   -- disable mouse look
    DisableControlAction(0, 263, true) -- disable melee
    DisableControlAction(0, 264, true) -- disable melee
    DisableControlAction(0, 257, true) -- disable melee
    DisableControlAction(0, 140, true) -- disable melee
    DisableControlAction(0, 141, true) -- disable melee
    DisableControlAction(0, 142, true) -- disable melee
    DisableControlAction(0, 143, true) -- disable melee
    DisableControlAction(0, 177, true) -- disable escape
    DisableControlAction(0, 200, true) -- disable escape
    DisableControlAction(0, 202, true) -- disable escape
    DisableControlAction(0, 322, true) -- disable escape
    
    -- CATATAN: Kita TIDAK mematikan Group 30 (Move LR) dan 31 (Move UD)
    -- agar WASD tetap berfungsi.
end

-- local function DisableDisplayControlActions()
--     DisableControlAction(0, 1, true)   -- disable mouse look
--     DisableControlAction(0, 2, true)   -- disable mouse look
--     DisableControlAction(0, 3, true)   -- disable mouse look
--     DisableControlAction(0, 4, true)   -- disable mouse look
--     DisableControlAction(0, 5, true)   -- disable mouse look
--     DisableControlAction(0, 6, true)   -- disable mouse look
--     DisableControlAction(0, 263, true) -- disable melee
--     DisableControlAction(0, 264, true) -- disable melee
--     DisableControlAction(0, 257, true) -- disable melee
--     DisableControlAction(0, 140, true) -- disable melee
--     DisableControlAction(0, 141, true) -- disable melee
--     DisableControlAction(0, 142, true) -- disable melee
--     DisableControlAction(0, 143, true) -- disable melee
--     DisableControlAction(0, 177, true) -- disable escape
--     DisableControlAction(0, 200, true) -- disable escape
--     DisableControlAction(0, 202, true) -- disable escape
--     DisableControlAction(0, 322, true) -- disable escape
--     DisableControlAction(0, 245, true) -- disable chat
-- end

local function LoadPhone()
    Wait(100)
    ESX.TriggerServerCallback('qb-phone:server:GetPhoneData', function(pData)
        PhoneData.PlayerData = ESX.GetPlayerData()
        PlayerJob = PhoneData.PlayerData.job
        
        -- ============================================================
        -- 1. FIX FORMAT UANG (Agar Bank.js tidak error)
        -- ============================================================
        PhoneData.PlayerData.money = {
            bank = 0,
            cash = 0
        }

        if PhoneData.PlayerData.accounts then
            for _, account in pairs(PhoneData.PlayerData.accounts) do
                if account.name == 'bank' then
                    PhoneData.PlayerData.money.bank = account.money
                elseif account.name == 'money' then
                    PhoneData.PlayerData.money.cash = account.money
                end
            end
        end
        
        if PhoneData.PlayerData.job == nil then
            PhoneData.PlayerData.job = { name = "unemployed", label = "Unemployed", onduty = true }
        else
            PhoneData.PlayerData.job.onduty = true 
        end

        -- ============================================================
        -- 2. FIX LOAD SETTINGS (BACKGROUND & FOTO PROFIL)
        -- ============================================================
        -- PERBAIKAN: Server mengirim 'MetaData', bukan 'PhoneMeta'
        local PhoneMeta = pData.MetaData or {} 
        PhoneData.MetaData = PhoneMeta

        -- Cek Profile Picture
        if PhoneData.MetaData.profilepicture == nil then
            PhoneData.MetaData.profilepicture = 'default'
        end

        -- Cek Background
        if PhoneData.MetaData.background == nil then
            PhoneData.MetaData.background = "default-qbcore"
        end

        if PhoneData.MetaData.frame == nil then
            PhoneData.MetaData.frame = "samsung-s10" -- Ganti sesuai nama file frame default kamu
        end
        -- ============================================================

        -- Load Aplikasi
        for appName, AppData in pairs(Config.StoreApps) do
            Config.PhoneApplications[appName] = {
                app = appName,
                color = AppData.color,
                icon = AppData.icon,
                tooltipText = AppData.title,
                tooltipPos = 'right',
                job = AppData.job,
                blockedjobs = AppData.blockedjobs,
                slot = AppData.slot,
                Alerts = 0,
            }
        end

        if pData.Applications ~= nil and next(pData.Applications) ~= nil then
            for k, v in pairs(pData.Applications) do
                if Config.PhoneApplications[k] then
                    Config.PhoneApplications[k].Alerts = v
                end
            end
        end

        -- Load Data Lainnya
        if pData.MentionedTweets ~= nil then PhoneData.MentionedTweets = pData.MentionedTweets end
        if pData.PlayerContacts ~= nil then PhoneData.Contacts = pData.PlayerContacts end
        if pData.Hashtags ~= nil then PhoneData.Hashtags = pData.Hashtags end
        if pData.Tweets ~= nil then PhoneData.Tweets = pData.Tweets end
        if pData.Mails ~= nil then PhoneData.Mails = pData.Mails end
        if pData.Adverts ~= nil then PhoneData.Adverts = pData.Adverts end
        if pData.CryptoTransactions ~= nil then PhoneData.CryptoTransactions = pData.CryptoTransactions end
        if pData.Images ~= nil then PhoneData.Images = pData.Images end

        if pData.Chats ~= nil and next(pData.Chats) ~= nil then
            local Chats = {}
            for _, v in pairs(pData.Chats) do
                Chats[v.number] = {
                    name = IsNumberInContacts(v.number),
                    number = v.number,
                    messages = json.decode(v.messages)
                }
            end
            PhoneData.Chats = Chats
        end

        SendNUIMessage({
            action = 'LoadPhoneData',
            PhoneData = PhoneData,
            PlayerData = PhoneData.PlayerData,
            PlayerJob = PhoneData.PlayerData.job,
            applications = Config.PhoneApplications,
            PlayerId = GetPlayerServerId(PlayerId())
        })
    end)
end

local function OpenPhone()
    ESX.TriggerServerCallback('qb-phone:server:HasPhone', function(HasPhone)
        if HasPhone then
            -- 1. PANGGIL CALLBACK KHUSUS UNTUK MINTA NOMOR HP TERBARU
            ESX.TriggerServerCallback('qb-phone:server:GetMyNumber', function(myRealNumber)
                
                local RawPlayerData = ESX.GetPlayerData()
                
                -- Format Uang
                RawPlayerData.money = { bank = 0, cash = 0 }
                if RawPlayerData.accounts then
                    for _, account in pairs(RawPlayerData.accounts) do
                        if account.name == 'bank' then RawPlayerData.money.bank = account.money
                        elseif account.name == 'money' then RawPlayerData.money.cash = account.money end
                    end
                end

                -- Konstruksi Charinfo dengan Nomor HP dari Server
                RawPlayerData.charinfo = {}
                RawPlayerData.charinfo.firstname = RawPlayerData.firstName or "Citizen"
                RawPlayerData.charinfo.lastname = RawPlayerData.lastName or "Unknown"
                
                -- GANTI '00000' DENGAN NOMOR ASLI DARI SERVER
                RawPlayerData.charinfo.phone = myRealNumber or "00000"
                RawPlayerData.charinfo.account = myRealNumber or "00000" -- Bank account ikut nomor hp

                PhoneData.PlayerData = RawPlayerData

                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(true)
                SendNUIMessage({
                    action = 'open',
                    Tweets = PhoneData.Tweets,
                    AppData = Config.PhoneApplications,
                    CallData = PhoneData.CallData,
                    PlayerData = PhoneData.PlayerData,
                })
                PhoneData.isOpen = true

                CreateThread(function()
                    while PhoneData.isOpen do
                        DisableDisplayControlActions()
                        Wait(1)
                    end
                end)

                if not PhoneData.CallData.InCall then
                    DoPhoneAnimation('cellphone_text_in')
                else
                    DoPhoneAnimation('cellphone_call_to_text')
                end

                SetTimeout(250, function()
                    newPhoneProp()
                end)

                ESX.TriggerServerCallback('qb-phone:server:GetMyVehicles', function(vehicles)
                    for k, v in pairs(vehicles) do
                        local modelHash = v.model
                        if type(modelHash) == 'string' then modelHash = GetHashKey(modelHash) end
                        local displayName = GetDisplayNameFromVehicleModel(modelHash)
                        local labelName = GetLabelText(displayName)
                        if labelName == "NULL" then labelName = displayName end
                        v.fullname = labelName
                        v.model = labelName
                    end
                    PhoneData.GarageVehicles = vehicles
                end)
            end) -- End Callback GetMyNumber
        else
            ESX.ShowNotification("You don't have a phone")
        end
    end)
end

local function GenerateCallId(caller, target)
    local CallId = math.ceil(((tonumber(caller) + tonumber(target)) / 100 * 1))
    return CallId
end

local function CancelCall()
    TriggerServerEvent('qb-phone:server:CancelCall', PhoneData.CallData)
    if PhoneData.CallData.CallType == 'ongoing' then
        exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
    end
    PhoneData.CallData.CallType = nil
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = {}
    PhoneData.CallData.CallId = nil

    if not PhoneData.isOpen then
        StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
        deletePhone()
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    end

    TriggerServerEvent('qb-phone:server:SetCallState', false)

    if not PhoneData.isOpen then
        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Phone',
                text = 'The call has been ended',
                icon = 'fas fa-phone',
                color = '#e84118',
            },
        })
    else
        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Phone',
                text = 'The call has been ended',
                icon = 'fas fa-phone',
                color = '#e84118',
            },
        })

        SendNUIMessage({
            action = 'SetupHomeCall',
            CallData = PhoneData.CallData,
        })

        SendNUIMessage({
            action = 'CancelOutgoingCall',
        })
    end
end

local function CallContact(CallData, AnonymousCall)
    local RepeatCount = 0
    PhoneData.CallData.CallType = 'outgoing'
    PhoneData.CallData.InCall = true
    PhoneData.CallData.TargetData = CallData
    PhoneData.CallData.AnsweredCall = false
    -- Mendapatkan Nomor HP Sendiri (Sesuaikan dengan cara Anda menyimpan nomor hp di ESX)
    local myNumber = "000000" -- Default
    if PhoneData.PlayerData and PhoneData.PlayerData.charinfo and PhoneData.PlayerData.charinfo.phone then
        myNumber = PhoneData.PlayerData.charinfo.phone 
    end
    -- Jika menggunakan gcphone / esx_addons_gcphone, kadang ada di properties lain
    
    PhoneData.CallData.CallId = GenerateCallId(myNumber, CallData.number)

    TriggerServerEvent('qb-phone:server:CallContact', PhoneData.CallData.TargetData, PhoneData.CallData.CallId, AnonymousCall)
    TriggerServerEvent('qb-phone:server:SetCallState', true)

    for _ = 1, Config.CallRepeats + 1, 1 do
        if not PhoneData.CallData.AnsweredCall then
            if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                if PhoneData.CallData.InCall then
                    RepeatCount = RepeatCount + 1
                    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)
                else
                    break
                end
                Wait(Config.RepeatTimeout)
            else
                CancelCall()
                break
            end
        else
            break
        end
    end
end

local function AnswerCall()
    if (PhoneData.CallData.CallType == 'incoming' or PhoneData.CallData.CallType == 'outgoing') and PhoneData.CallData.InCall and not PhoneData.CallData.AnsweredCall then
        PhoneData.CallData.CallType = 'ongoing'
        PhoneData.CallData.AnsweredCall = true
        PhoneData.CallData.CallTime = 0

        SendNUIMessage({ action = 'AnswerCall', CallData = PhoneData.CallData })
        SendNUIMessage({ action = 'SetupHomeCall', CallData = PhoneData.CallData })

        TriggerServerEvent('qb-phone:server:SetCallState', true)

        if PhoneData.isOpen then
            DoPhoneAnimation('cellphone_text_to_call')
        else
            DoPhoneAnimation('cellphone_call_listen_base')
        end

        CreateThread(function()
            while true do
                if PhoneData.CallData.AnsweredCall then
                    PhoneData.CallData.CallTime = PhoneData.CallData.CallTime + 1
                    SendNUIMessage({
                        action = 'UpdateCallTime',
                        Time = PhoneData.CallData.CallTime,
                        Name = PhoneData.CallData.TargetData.name,
                    })
                else
                    break
                end

                Wait(1000)
            end
        end)

        TriggerServerEvent('qb-phone:server:AnswerCall', PhoneData.CallData)
        exports['pma-voice']:addPlayerToCall(PhoneData.CallData.CallId)
    else
        PhoneData.CallData.InCall = false
        PhoneData.CallData.CallType = nil
        PhoneData.CallData.AnsweredCall = false

        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Phone',
                text = "You don't have a incoming call...",
                icon = 'fas fa-phone',
                color = '#e84118',
            },
        })
    end
end

local function CellFrontCamActivate(activate)
    return Citizen.InvokeNative(0x2491A93618B7D838, activate)
end

-- Command

RegisterCommand('phone', function()
    local PlayerData = ESX.GetPlayerData()
    local isDead = false
    if IsEntityDead(PlayerPedId()) then isDead = true end

    if not PhoneData.isOpen then
        if not isDead and not IsPauseMenuActive() then
            OpenPhone()
        else
            ESX.ShowNotification('Action not available at the moment..')
        end
    end
end)

--RegisterKeyMapping('phone', 'Open Phone', 'keyboard', Config.OpenPhone)

-- NUI Callbacks

RegisterNUICallback('CancelOutgoingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('DenyIncomingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('CancelOngoingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('AnswerCall', function(_, cb)
    AnswerCall()
    cb('ok')
end)

RegisterNUICallback('ClearRecentAlerts', function(_, cb)
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'phone', 0)
    Config.PhoneApplications['phone'].Alerts = 0
    SendNUIMessage({ action = 'RefreshAppAlerts', AppData = Config.PhoneApplications })
    cb('ok')
end)

RegisterNUICallback('SetBackground', function(data, cb)
    local background = data.background
    PhoneData.MetaData.background = background
    TriggerServerEvent('qb-phone:server:SaveMetaData', PhoneData.MetaData)
    cb('ok')
end)

RegisterNUICallback('GetMissedCalls', function(_, cb)
    cb(PhoneData.RecentCalls)
end)

RegisterNUICallback('GetSuggestedContacts', function(_, cb)
    cb(PhoneData.SuggestedContacts)
end)

RegisterNUICallback('HasPhone', function(_, cb)
    ESX.TriggerServerCallback('qb-phone:server:HasPhone', function(HasPhone)
        cb(HasPhone)
    end)
end)

RegisterNUICallback('SetupGarageVehicles', function(_, cb)
    cb(PhoneData.GarageVehicles)
end)

RegisterNUICallback('RemoveMail', function(data, cb)
    local MailId = data.mailId
    TriggerServerEvent('qb-phone:server:RemoveMail', MailId)
    cb('ok')
end)

RegisterNUICallback('Close', function(_, cb)
    if not PhoneData.CallData.InCall then
        DoPhoneAnimation('cellphone_text_out')
        SetTimeout(400, function()
            StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
            deletePhone()
            PhoneData.AnimationData.lib = nil
            PhoneData.AnimationData.anim = nil
        end)
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
        DoPhoneAnimation('cellphone_text_to_call')
    end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetTimeout(500, function()
        PhoneData.isOpen = false
    end)
    cb('ok')
end)

RegisterNUICallback('AcceptMailButton', function(data, cb)
    if data.buttonEvent ~= nil or data.buttonData ~= nil then
        TriggerEvent(data.buttonEvent, data.buttonData)
    end
    TriggerServerEvent('qb-phone:server:ClearButtonData', data.mailId)
    cb('ok')
end)

RegisterNUICallback('AddNewContact', function(data, cb)
    PhoneData.Contacts[#PhoneData.Contacts + 1] = {
        name = data.ContactName,
        number = data.ContactNumber,
        iban = data.ContactIban
    }
    Wait(100)
    cb(PhoneData.Contacts)
    if PhoneData.Chats[data.ContactNumber] ~= nil and next(PhoneData.Chats[data.ContactNumber]) ~= nil then
        PhoneData.Chats[data.ContactNumber].name = data.ContactName
    end
    TriggerServerEvent('qb-phone:server:AddNewContact', data.ContactName, data.ContactNumber, data.ContactIban)
end)

RegisterNUICallback('GetMails', function(_, cb)
    cb(PhoneData.Mails)
end)

RegisterNUICallback('GetWhatsappChat', function(data, cb)
    if PhoneData.Chats[data.phone] ~= nil then
        cb(PhoneData.Chats[data.phone])
    else
        cb(false)
    end
end)

RegisterNUICallback('GetProfilePicture', function(data, cb)
    local number = data.number
    ESX.TriggerServerCallback('qb-phone:server:GetPicture', function(picture)
        cb(picture)
    end, number)
end)

RegisterNUICallback('GetBankContacts', function(_, cb)
    cb(PhoneData.Contacts)
end)

RegisterNUICallback('GetInvoices', function(_, cb)
    ESX.TriggerServerCallback('qb-phone:server:GetInvoices', function(resp)
        cb(resp)
    end)
end)

RegisterNUICallback('SharedLocation', function(data, cb)
    local x = data.coords.x
    local y = data.coords.y
    SetNewWaypoint(x, y)
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Whatsapp',
            text = 'Location has been set!',
            icon = 'fab fa-whatsapp',
            color = '#25D366',
            timeout = 1500,
        },
    })
    cb('ok')
end)

RegisterNUICallback('PostAdvert', function(data, cb)
    TriggerServerEvent('qb-phone:server:AddAdvert', data.message, data.url)
    cb('ok')
end)

RegisterNUICallback('DeleteAdvert', function(_, cb)
    TriggerServerEvent('qb-phone:server:DeleteAdvert')
    cb('ok')
end)

RegisterNUICallback('LoadAdverts', function(_, cb)
    -- Minta data terbaru dari Server
    ESX.TriggerServerCallback('qb-phone:server:GetAdverts', function(Adverts)
        -- Update data lokal
        PhoneData.Adverts = Adverts
        
        -- Kirim ke UI (Layar HP)
        SendNUIMessage({
            action = 'RefreshAdverts',
            Adverts = PhoneData.Adverts
        })
    end)
    cb({})
end)

RegisterNUICallback('ClearAlerts', function(data, cb)
    local chat = data.number
    local ChatKey = GetKeyByNumber(chat)

    if PhoneData.Chats[ChatKey].Unread ~= nil then
        local newAlerts = (Config.PhoneApplications['whatsapp'].Alerts - PhoneData.Chats[ChatKey].Unread)
        Config.PhoneApplications['whatsapp'].Alerts = newAlerts
        TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'whatsapp', newAlerts)

        PhoneData.Chats[ChatKey].Unread = 0

        SendNUIMessage({
            action = 'RefreshWhatsappAlerts',
            Chats = PhoneData.Chats,
        })
        SendNUIMessage({ action = 'RefreshAppAlerts', AppData = Config.PhoneApplications })
    end
    cb('ok')
end)

RegisterNUICallback('PayInvoice', function(data, cb)
    local senderCitizenId = data.senderCitizenId
    local society = data.society
    local amount = data.amount
    local invoiceId = data.invoiceId
    ESX.TriggerServerCallback('qb-phone:server:PayInvoice', function(resp)
        cb(resp)
    end, society, amount, invoiceId, senderCitizenId)
    TriggerServerEvent('qb-phone:server:BillingEmail', data, true)
end)

RegisterNUICallback('DeclineInvoice', function(data, cb)
    local society = data.society
    local amount = data.amount
    local invoiceId = data.invoiceId
    ESX.TriggerServerCallback('qb-phone:server:DeclineInvoice', function(resp)
        cb(resp)
    end, society, amount, invoiceId)
    TriggerServerEvent('qb-phone:server:BillingEmail', data, false)
end)

RegisterNUICallback('EditContact', function(data, cb)
    local NewName = data.CurrentContactName
    local NewNumber = data.CurrentContactNumber
    local NewIban = data.CurrentContactIban
    local OldName = data.OldContactName
    local OldNumber = data.OldContactNumber
    local OldIban = data.OldContactIban
    for _, v in pairs(PhoneData.Contacts) do
        if v.name == OldName and v.number == OldNumber then
            v.name = NewName
            v.number = NewNumber
            v.iban = NewIban
        end
    end
    if PhoneData.Chats[NewNumber] ~= nil and next(PhoneData.Chats[NewNumber]) ~= nil then
        PhoneData.Chats[NewNumber].name = NewName
    end
    Wait(100)
    cb(PhoneData.Contacts)
    TriggerServerEvent('qb-phone:server:EditContact', NewName, NewNumber, NewIban, OldName, OldNumber, OldIban)
end)

RegisterNUICallback('GetHashtagMessages', function(data, cb)
    if PhoneData.Hashtags[data.hashtag] ~= nil and next(PhoneData.Hashtags[data.hashtag]) ~= nil then
        cb(PhoneData.Hashtags[data.hashtag])
    else
        cb(nil)
    end
end)

RegisterNUICallback('GetTweets', function(_, cb)
    cb(PhoneData.Tweets)
end)

RegisterNUICallback('UpdateProfilePicture', function(data, cb)
    local pf = data.profilepicture
    PhoneData.MetaData.profilepicture = pf
    TriggerServerEvent('qb-phone:server:SaveMetaData', PhoneData.MetaData)
    cb('ok')
end)

RegisterNUICallback('PostNewTweet', function(data, cb)
    local TweetMessage = {
        firstName = PhoneData.PlayerData.firstName or "First",
        lastName = PhoneData.PlayerData.lastName or "Last",
        citizenid = PhoneData.PlayerData.identifier,
        message = escape_str(data.Message),
        time = data.Date,
        tweetId = GenerateTweetId(),
        picture = data.Picture,
        url = data.url
    }

    local TwitterMessage = data.Message
    local MentionTag = TwitterMessage:split('@')
    local Hashtag = TwitterMessage:split('#')
    if #Hashtag <= 3 then
        for i = 2, #Hashtag, 1 do
            local Handle = Hashtag[i]:split(' ')[1]
            if Handle ~= nil or Handle ~= '' then
                local InvalidSymbol = string.match(Handle, patt)
                if InvalidSymbol then
                    Handle = Handle:gsub('%' .. InvalidSymbol, '')
                end
                TriggerServerEvent('qb-phone:server:UpdateHashtags', Handle, TweetMessage)
            end
        end

        for i = 2, #MentionTag, 1 do
            local Handle = MentionTag[i]:split(' ')[1]
            if Handle ~= nil or Handle ~= '' then
                local Fullname = Handle:split('_')
                local Firstname = Fullname[1]
                table.remove(Fullname, 1)
                local Lastname = table.concat(Fullname, ' ')

                if (Firstname ~= nil and Firstname ~= '') and (Lastname ~= nil and Lastname ~= '') then
                    if Firstname ~= PhoneData.PlayerData.firstName and Lastname ~= PhoneData.PlayerData.lastName then
                        TriggerServerEvent('qb-phone:server:MentionedPlayer', Firstname, Lastname, TweetMessage)
                    end
                end
            end
        end

        PhoneData.Tweets[#PhoneData.Tweets + 1] = TweetMessage
        Wait(100)
        cb(PhoneData.Tweets)

        TriggerServerEvent('qb-phone:server:UpdateTweets', PhoneData.Tweets, TweetMessage)
    else
        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Twitter',
                text = 'Invalid Tweet',
                icon = 'fab fa-twitter',
                color = '#1DA1F2',
                timeout = 1000,
            },
        })
    end
end)

RegisterNUICallback('DeleteTweet', function(data, cb)
    TriggerServerEvent('qb-phone:server:DeleteTweet', data.id)
    cb('ok')
end)

RegisterNUICallback('GetMentionedTweets', function(_, cb)
    cb(PhoneData.MentionedTweets)
end)

RegisterNUICallback('GetHashtags', function(_, cb)
    if PhoneData.Hashtags ~= nil and next(PhoneData.Hashtags) ~= nil then
        cb(PhoneData.Hashtags)
    else
        cb(nil)
    end
end)

RegisterNUICallback('FetchSearchResults', function(data, cb)
    ESX.TriggerServerCallback('qb-phone:server:FetchResult', function(result)
        cb(result)
    end, data.input)
end)

local function GetFirstAvailableSlot() -- Placeholder
    return nil
end
local CanDownloadApps = false

RegisterNUICallback('InstallApplication', function(data, cb)
    local ApplicationData = Config.StoreApps[data.app]
    local NewSlot = GetFirstAvailableSlot()

    if not CanDownloadApps then
        return
    end

    if NewSlot <= Config.MaxSlots then
        TriggerServerEvent('qb-phone:server:InstallApplication', {
            app = data.app,
        })
        cb({
            app = data.app,
            data = ApplicationData
        })
    else
        cb(false)
    end
end)

RegisterNUICallback('RemoveApplication', function(data, cb)
    TriggerServerEvent('qb-phone:server:RemoveInstallation', data.app)
    cb('ok')
end)

-- --- DEPENDENCY REMOVED: Trucker Job ---
RegisterNUICallback('GetTruckerData', function(_, cb)
    -- Stub: Mengembalikan data dummy atau nil
    cb({
        name = "Unknown",
        tier = "1",
        rep = 0
    })
end)

RegisterNUICallback('GetGalleryData', function(_, cb)
    local data = PhoneData.Images
    cb(data)
end)

RegisterNUICallback('DeleteImage', function(image, cb)
    TriggerServerEvent('qb-phone:server:RemoveImageFromGallery', image)
    Wait(400)
    TriggerServerEvent('qb-phone:server:getImageFromGallery')
    cb(true)
end)


RegisterNUICallback('track-vehicle', function(data, cb)
    local veh = data.veh
    if findVehFromPlateAndLocate(veh.plate) then
        ESX.ShowNotification('Your vehicle has been marked')
    else
        ESX.ShowNotification('This vehicle cannot be located')
    end
    cb('ok')
end)

RegisterNUICallback('DeleteContact', function(data, cb)
    local Name = data.CurrentContactName
    local Number = data.CurrentContactNumber

    for k, v in pairs(PhoneData.Contacts) do
        if v.name == Name and v.number == Number then
            table.remove(PhoneData.Contacts, k)
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'Phone',
                    text = 'You deleted contact!',
                    icon = 'fa fa-phone-alt',
                    color = '#04b543',
                    timeout = 1500,
                },
            })
            break
        end
    end
    Wait(100)
    cb(PhoneData.Contacts)
    if PhoneData.Chats[Number] ~= nil and next(PhoneData.Chats[Number]) ~= nil then
        PhoneData.Chats[Number].name = Number
    end
    TriggerServerEvent('qb-phone:server:RemoveContact', Name, Number)
end)

-- --- DEPENDENCY REMOVED: Crypto ---
-- Semua fitur crypto dimatikan agar tidak error
RegisterNUICallback('GetCryptoData', function(data, cb)
    -- Stub
    cb({
        History = {},
        Portfolio = 0,
        Worth = 0,
        WalletId = "Disabled"
    })
end)

RegisterNUICallback('BuyCrypto', function(data, cb)
    ESX.ShowNotification('Crypto feature is disabled.')
    cb({
        History = {},
        Portfolio = 0,
        Worth = 0,
        WalletId = "Disabled"
    })
end)

RegisterNUICallback('SellCrypto', function(data, cb)
    ESX.ShowNotification('Crypto feature is disabled.')
    cb({
        History = {},
        Portfolio = 0,
        Worth = 0,
        WalletId = "Disabled"
    })
end)

RegisterNUICallback('TransferCrypto', function(data, cb)
    ESX.ShowNotification('Crypto feature is disabled.')
    cb({
        History = {},
        Portfolio = 0,
        Worth = 0,
        WalletId = "Disabled"
    })
end)

RegisterNUICallback('GetCryptoTransactions', function(_, cb)
    local Data = {
        CryptoTransactions = PhoneData.CryptoTransactions or {}
    }
    cb(Data)
end)

-- --- DEPENDENCY REMOVED: Racing ---
-- Semua fitur racing dimatikan
RegisterNUICallback('GetAvailableRaces', function(_, cb)
    cb({})
end)

RegisterNUICallback('JoinRace', function(data, cb)
    ESX.ShowNotification('Racing feature is disabled.')
    cb('ok')
end)

RegisterNUICallback('LeaveRace', function(data, cb)
    ESX.ShowNotification('Racing feature is disabled.')
    cb('ok')
end)

RegisterNUICallback('StartRace', function(data, cb)
    ESX.ShowNotification('Racing feature is disabled.')
    cb('ok')
end)

RegisterNUICallback('SetAlertWaypoint', function(data, cb)
    local coords = data.alert.coords
    ESX.ShowNotification('GPS Location set: ' .. data.alert.title)
    SetNewWaypoint(coords.x, coords.y)
    cb('ok')
end)

RegisterNUICallback('RemoveSuggestion', function(data, cb)
    data = data.data
    if PhoneData.SuggestedContacts ~= nil and next(PhoneData.SuggestedContacts) ~= nil then
        for k, v in pairs(PhoneData.SuggestedContacts) do
            if (data.name[1] == v.name[1] and data.name[2] == v.name[2]) and data.number == v.number and data.bank == v.bank then
                table.remove(PhoneData.SuggestedContacts, k)
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('FetchVehicleResults', function(data, cb)
    ESX.TriggerServerCallback('qb-phone:server:GetVehicleSearchResults', function(result)
        if result ~= nil then
            for k, _ in pairs(result) do
                -- Simplified flagging check
                result[k].isFlagged = false
                Wait(50)
            end
        end
        cb(result)
    end, data.input)
end)

RegisterNUICallback('FetchVehicleScan', function(_, cb)
    local vehicle = ESX.Game.GetClosestVehicle()
    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local vehname = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    ESX.TriggerServerCallback('qb-phone:server:ScanPlate', function(result)
        result.isFlagged = false
        result.label = GetLabelText(vehname) 
        cb(result)
    end, plate)
end)

-- --- Racing Callbacks (Stubbed) ---
RegisterNUICallback('GetRaces', function(_, cb) cb({}) end)
RegisterNUICallback('GetTrackData', function(data, cb) cb({}) end)
RegisterNUICallback('SetupRace', function(data, cb) cb('ok') end)
RegisterNUICallback('HasCreatedRace', function(_, cb) cb(false) end)
RegisterNUICallback('IsInRace', function(_, cb) cb(false) end)
RegisterNUICallback('IsAuthorizedToCreateRaces', function(data, cb) cb({IsAuthorized = false, IsBusy = false, IsNameAvailable = false}) end)
RegisterNUICallback('StartTrackEditor', function(data, cb) cb('ok') end)
RegisterNUICallback('GetRacingLeaderboards', function(_, cb) cb({}) end)
RegisterNUICallback('RaceDistanceCheck', function(data, cb) cb(false) end)
RegisterNUICallback('IsBusyCheck', function(data, cb) cb(false) end)
RegisterNUICallback('CanRaceSetup', function(_, cb) cb(false) end)

-- --- DEPENDENCY REMOVED: Houses ---
RegisterNUICallback('GetPlayerHouses', function(_, cb) cb({}) end)
RegisterNUICallback('GetPlayerKeys', function(_, cb) cb({}) end)
RegisterNUICallback('SetHouseLocation', function(data, cb) cb('ok') end)
RegisterNUICallback('RemoveKeyholder', function(data, cb) cb('ok') end)
RegisterNUICallback('TransferCid', function(data, cb) cb(false) end)
RegisterNUICallback('FetchPlayerHouses', function(data, cb) cb({}) end)

RegisterNUICallback('SetGPSLocation', function(data, cb)
    SetNewWaypoint(data.coords.x, data.coords.y)
    ESX.ShowNotification('GPS has been set!')
    cb('ok')
end)

RegisterNUICallback('SetApartmentLocation', function(data, cb)
    local ApartmentData = data.data.appartmentdata
    if ApartmentData then
         -- Logic apartment custom, biasanya ESX tidak punya default
         ESX.ShowNotification('Apartment location not available')
    end
    cb('ok')
end)

RegisterNUICallback('GetCurrentLawyers', function(_, cb)
    ESX.TriggerServerCallback('qb-phone:server:GetCurrentLawyers', function(lawyers)
        cb(lawyers)
    end)
end)

RegisterNUICallback('SetupStoreApps', function(_, cb)
    local PlayerData = ESX.GetPlayerData()
    local data = {
        StoreApps = Config.StoreApps,
        PhoneData = {}
    }
    cb(data)
end)

RegisterNUICallback('ClearMentions', function(_, cb)
    Config.PhoneApplications['twitter'].Alerts = 0
    SendNUIMessage({
        action = 'RefreshAppAlerts',
        AppData = Config.PhoneApplications
    })
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'twitter', 0)
    SendNUIMessage({ action = 'RefreshAppAlerts', AppData = Config.PhoneApplications })
    cb('ok')
end)

RegisterNUICallback('ClearGeneralAlerts', function(data, cb)
    SetTimeout(400, function()
        Config.PhoneApplications[data.app].Alerts = 0
        SendNUIMessage({
            action = 'RefreshAppAlerts',
            AppData = Config.PhoneApplications
        })
        TriggerServerEvent('qb-phone:server:SetPhoneAlerts', data.app, 0)
        SendNUIMessage({ action = 'RefreshAppAlerts', AppData = Config.PhoneApplications })
        cb('ok')
    end)
end)

RegisterNUICallback('TransferMoney', function(data, cb)
    data.amount = tonumber(data.amount)
    -- Cek saldo client side (Account Bank)
    local bankMoney = 0
    local PlayerData = ESX.GetPlayerData()
    for i=1, #PlayerData.accounts do
        if PlayerData.accounts[i].name == 'bank' then
            bankMoney = PlayerData.accounts[i].money
            break
        end
    end

    if tonumber(bankMoney) >= data.amount then
        local amaountata = bankMoney - data.amount
        TriggerServerEvent('qb-phone:server:TransferMoney', data.iban, data.amount)
        local cbdata = {
            CanTransfer = true,
            NewAmount = amaountata
        }
        cb(cbdata)
    else
        local cbdata = {
            CanTransfer = false,
            NewAmount = nil,
        }
        cb(cbdata)
    end
end)

RegisterNUICallback('CanTransferMoney', function(data, cb)
    local amount = tonumber(data.amountOf)
    local iban = data.sendTo
    local PlayerData = ESX.GetPlayerData()
    local bankMoney = 0
    for i=1, #PlayerData.accounts do
        if PlayerData.accounts[i].name == 'bank' then
            bankMoney = PlayerData.accounts[i].money
            break
        end
    end

    if (bankMoney - amount) >= 0 then
        ESX.TriggerServerCallback('qb-phone:server:CanTransferMoney', function(Transferd)
            if Transferd then
                cb({ TransferedMoney = true, NewBalance = (bankMoney - amount) })
            else
                SendNUIMessage({ action = 'PhoneNotification', PhoneNotify = { timeout = 3000, title = 'Bank', text = 'Account does not exist!', icon = 'fas fa-university', color = '#ff0000', }, })
                cb({ TransferedMoney = false })
            end
        end, amount, iban)
    else
        cb({ TransferedMoney = false })
    end
end)

RegisterNUICallback('GetWhatsappChats', function(_, cb)
    ESX.TriggerServerCallback('qb-phone:server:GetContactPictures', function(Chats)
        cb(Chats)
    end, PhoneData.Chats)
end)

RegisterNUICallback('CallContact', function(data, cb)
    ESX.TriggerServerCallback('qb-phone:server:GetCallState', function(CanCall, IsOnline, _)
        local status = {
            CanCall = CanCall,
            IsOnline = IsOnline,
            InCall = PhoneData.CallData.InCall,
        }
        cb(status)
        -- Custom Identifier/Phone Number
        local myPhone = "000000"
        if PhoneData.PlayerData and PhoneData.PlayerData.charinfo then
             myPhone = PhoneData.PlayerData.charinfo.phone
        end
        
        if CanCall and not status.InCall and (data.ContactData.number ~= myPhone) then
            CallContact(data.ContactData, data.Anonymous)
        end
    end, data.ContactData)
end)

RegisterNUICallback('SendMessage', function(data, cb)
    local ChatMessage = data.ChatMessage
    local ChatDate = data.ChatDate
    local ChatNumber = data.ChatNumber
    local ChatTime = data.ChatTime
    local ChatType = data.ChatType
    local Ped = PlayerPedId()
    local Pos = GetEntityCoords(Ped)
    local NumberKey = GetKeyByNumber(ChatNumber)
    local ChatKey = GetKeyByDate(NumberKey, ChatDate)
    
    -- PASTIKAN IDENTIFIER ADA (Fallback ke 'Unknown' jika nil)
    local myIdentifier = PhoneData.PlayerData.identifier or "Unknown"

    if PhoneData.Chats[NumberKey] ~= nil then
        if (PhoneData.Chats[NumberKey].messages == nil) then
            PhoneData.Chats[NumberKey].messages = {}
        end
        if PhoneData.Chats[NumberKey].messages[ChatKey] ~= nil then
            if ChatType == 'message' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {},
                }
            elseif ChatType == 'location' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = 'Shared Location',
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {
                        x = Pos.x,
                        y = Pos.y,
                    },
                }
            elseif ChatType == 'picture' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = 'Photo',
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {
                        url = data.url
                    },
                }
            end
            TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, false)
            NumberKey = GetKeyByNumber(ChatNumber)
            ReorganizeChats(NumberKey)
        else
            PhoneData.Chats[NumberKey].messages[#PhoneData.Chats[NumberKey].messages + 1] = {
                date = ChatDate,
                messages = {},
            }
            ChatKey = GetKeyByDate(NumberKey, ChatDate)
            if ChatType == 'message' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {},
                }
            elseif ChatType == 'location' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = 'Shared Location',
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {
                        x = Pos.x,
                        y = Pos.y,
                    },
                }
            elseif ChatType == 'picture' then
                PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                    message = 'Photo',
                    time = ChatTime,
                    sender = myIdentifier,
                    type = ChatType,
                    data = {
                        url = data.url
                    },
                }
            end
            TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, true)
            NumberKey = GetKeyByNumber(ChatNumber)
            ReorganizeChats(NumberKey)
        end
    else
        PhoneData.Chats[#PhoneData.Chats + 1] = {
            name = IsNumberInContacts(ChatNumber),
            number = ChatNumber,
            messages = {},
        }
        NumberKey = GetKeyByNumber(ChatNumber)
        PhoneData.Chats[NumberKey].messages[#PhoneData.Chats[NumberKey].messages + 1] = {
            date = ChatDate,
            messages = {},
        }
        ChatKey = GetKeyByDate(NumberKey, ChatDate)
        if ChatType == 'message' then
            PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                message = ChatMessage,
                time = ChatTime,
                sender = myIdentifier,
                type = ChatType,
                data = {},
            }
        elseif ChatType == 'location' then
            PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                message = 'Shared Location',
                time = ChatTime,
                sender = myIdentifier,
                type = ChatType,
                data = {
                    x = Pos.x,
                    y = Pos.y,
                },
            }
        elseif ChatType == 'picture' then
            PhoneData.Chats[NumberKey].messages[ChatKey].messages[#PhoneData.Chats[NumberKey].messages[ChatKey].messages + 1] = {
                message = 'Photo',
                time = ChatTime,
                sender = myIdentifier,
                type = ChatType,
                data = {
                    url = data.url
                },
            }
        end
        TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, true)
        NumberKey = GetKeyByNumber(ChatNumber)
        ReorganizeChats(NumberKey)
    end

    -- PENTING: Update UI Langsung tanpa menunggu server (Optimistic Update)
    -- Ini memastikan chat MUNCUL seketika, meskipun teman offline
    ESX.TriggerServerCallback('qb-phone:server:GetContactPicture', function(Chat)
        SendNUIMessage({
            action = 'UpdateChat',
            chatData = PhoneData.Chats[GetKeyByNumber(ChatNumber)], -- Gunakan data lokal terbaru
            chatNumber = ChatNumber,
        })
    end, PhoneData.Chats[GetKeyByNumber(ChatNumber)])
    
    cb({})
end)

local function SaveToInternalGallery()
    BeginTakeHighQualityPhoto()
    SaveHighQualityPhoto(0)
    FreeMemoryForHighQualityPhoto()
end

RegisterNUICallback('TakePhoto', function(_, cb)
    SetNuiFocus(false, false)
    CreateMobilePhone(1)
    CellCamActivate(true, true)
    
    local takePhoto = true
    local showInstructions = true -- 1. Variabel kontrol untuk instruksi

    while takePhoto do
        -- 2. Tampilkan instruksi HANYA jika showInstructions bernilai true
        if showInstructions then
            SetTextComponentFormat("STRING")
            AddTextComponentString("~INPUT_CELLPHONE_SELECT~ Foto ~n~~INPUT_CELLPHONE_CANCEL~ Kembali ~n~~INPUT_PHONE~ Ganti Kamera")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
        end

        if IsControlJustPressed(1, 27) then -- Toogle Mode (Panah Atas)
            frontCam = not frontCam
            CellFrontCamActivate(frontCam)
        elseif IsControlJustPressed(1, 177) then -- CANCEL (Backspace/Klik Kanan)
            DestroyMobilePhone()
            CellCamActivate(false, false)
            cb(json.encode({ url = nil }))
            break
        elseif IsControlJustPressed(1, 176) then -- TAKE PIC (Enter/Klik Kiri)
            
            -- 3. Matikan instruksi segera saat tombol ditekan
            showInstructions = false 
            ClearAllHelpMessages() -- Hapus teks paksa agar bersih saat difoto

            if Config.Fivemerr == true then
                return ESX.TriggerServerCallback('qb-phone:server:UploadToFivemerr', function(fivemerrData)
                    if fivemerrData == nil then
                        DestroyMobilePhone()
                        CellCamActivate(false, false)
                        return
                    end

                    SaveToInternalGallery()
                    local imageData = json.decode(fivemerrData)
                    DestroyMobilePhone()
                    CellCamActivate(false, false)
                    TriggerServerEvent('qb-phone:server:addImageToGallery', imageData.url)
                    Wait(400)
                    TriggerServerEvent('qb-phone:server:getImageFromGallery')
                    cb(json.encode(imageData.url))
                end)
            end

            ESX.TriggerServerCallback('qb-phone:server:GetWebhook', function(hook)
                if not hook then
                    ESX.ShowNotification('Camera not setup', 'error')
                    -- Kembalikan instruksi jika error
                    showInstructions = true 
                    return
                end

                exports['screenshot-basic']:requestScreenshotUpload(tostring(hook), 'files[]', function(data)
                    SaveToInternalGallery()
                    local image = json.decode(data)
                    DestroyMobilePhone()
                    CellCamActivate(false, false)
                    TriggerServerEvent('qb-phone:server:addImageToGallery', image.attachments[1].proxy_url)
                    Wait(400)
                    TriggerServerEvent('qb-phone:server:getImageFromGallery')
                    cb(json.encode(image.attachments[1].proxy_url))
                    takePhoto = false
                end)
            end)
        end
        
        -- Sembunyikan HUD saat kamera aktif
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(19)
        HideHudAndRadarThisFrame()
        EnableAllControlActions(0)
        Wait(0)
    end
    Wait(1000)
    OpenPhone()
end)

RegisterCommand('ping', function(_, args)
    if not args[1] then
        ESX.ShowNotification('You need to input a Player ID')
    else
        TriggerServerEvent('qb-phone:server:sendPing', args[1])
    end
end, false)

-- Handler Events

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    LoadPhone()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    PhoneData = {
        MetaData = {},
        isOpen = false,
        PlayerData = nil,
        Contacts = {},
        Tweets = {},
        MentionedTweets = {},
        Hashtags = {},
        Chats = {},
        CallData = {},
        RecentCalls = {},
        Garage = {},
        Mails = {},
        Adverts = {},
        GarageVehicles = {},
        AnimationData = {
            lib = nil,
            anim = nil,
        },
        SuggestedContacts = {},
        CryptoTransactions = {},
    }
end)

RegisterNetEvent('esx:setJob', function(JobInfo)
    SendNUIMessage({
        action = 'UpdateApplications',
        JobData = JobInfo,
        applications = Config.PhoneApplications
    })

    PlayerJob = JobInfo
end)

-- Events

RegisterNetEvent('qb-phone:client:TransferMoney', function(amount, newmoney)
    -- Update local PlayerData accounts
    for i=1, #PhoneData.PlayerData.accounts do
        if PhoneData.PlayerData.accounts[i].name == 'bank' then
             PhoneData.PlayerData.accounts[i].money = newmoney
             break
        end
    end
    SendNUIMessage({ action = 'PhoneNotification', PhoneNotify = { title = 'QBank', text = '&#36;' .. amount .. ' has been added to your account!', icon = 'fas fa-university', color = '#8c7ae6', }, })
    SendNUIMessage({ action = 'UpdateBank', NewBalance = newmoney })
end)


RegisterNetEvent('qb-phone:client:UpdateTweets', function(src, Tweets, NewTweetData, delete)
    PhoneData.Tweets = Tweets
    local MyPlayerId = GetPlayerServerId(PlayerId())
    if not delete then -- New Tweet
        if src ~= MyPlayerId then
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'New Tweet (@' .. NewTweetData.firstName .. ' ' .. NewTweetData.lastName .. ')',
                    text = 'A new tweet as been posted.',
                    icon = 'fab fa-twitter',
                    color = '#1DA1F2',
                },
            })
            SendNUIMessage({
                action = 'UpdateTweets',
                Tweets = PhoneData.Tweets
            })
        else
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'Twitter',
                    text = 'The Tweet has been posted!',
                    icon = 'fab fa-twitter',
                    color = '#1DA1F2',
                    timeout = 1000,
                },
            })
        end
    else -- Deleting a tweet
        if src == MyPlayerId then
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'Twitter',
                    text = 'The Tweet has been deleted!',
                    icon = 'fab fa-twitter',
                    color = '#1DA1F2',
                    timeout = 1000,
                },
            })
        end
        SendNUIMessage({
            action = 'UpdateTweets',
            Tweets = PhoneData.Tweets
        })
    end
end)

RegisterNetEvent('qb-phone:client:RaceNotify', function(message)
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Racing',
            text = message,
            icon = 'fas fa-flag-checkered',
            color = '#353b48',
            timeout = 3500,
        },
    })
end)

RegisterNetEvent('qb-phone:client:AddRecentCall', function(data, time, type)
    PhoneData.RecentCalls[#PhoneData.RecentCalls + 1] = {
        name = IsNumberInContacts(data.number),
        time = time,
        type = type,
        number = data.number,
        anonymous = data.anonymous
    }
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'phone')
    Config.PhoneApplications['phone'].Alerts = Config.PhoneApplications['phone'].Alerts + 1
    SendNUIMessage({
        action = 'RefreshAppAlerts',
        AppData = Config.PhoneApplications
    })
end)

RegisterNetEvent('qb-phone-new:client:BankNotify', function(text)
    SendNUIMessage({
        action = 'PhoneNotification',
        NotifyData = {
            title = 'Bank',
            content = text,
            icon = 'fas fa-university',
            timeout = 3500,
            color = '#ff002f',
        },
    })
end)

RegisterNetEvent('qb-phone:client:NewMailNotify', function(MailData)
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Mail',
            text = 'You received a new mail from ' .. MailData.sender,
            icon = 'fas fa-envelope',
            color = '#ff002f',
            timeout = 1500,
        },
    })
    Config.PhoneApplications['mail'].Alerts = Config.PhoneApplications['mail'].Alerts + 1
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'mail')
end)

RegisterNetEvent('qb-phone:client:UpdateMails', function(NewMails)
    SendNUIMessage({
        action = 'UpdateMails',
        Mails = NewMails
    })
    PhoneData.Mails = NewMails
end)

RegisterNetEvent('qb-phone:client:UpdateAdvertsDel', function(Adverts)
    PhoneData.Adverts = Adverts
    SendNUIMessage({
        action = 'RefreshAdverts',
        Adverts = PhoneData.Adverts
    })
end)

RegisterNetEvent('qb-phone:client:UpdateAdverts', function(NewAdverts, LastAdName)
    -- Update data lokal
    PhoneData.Adverts = NewAdverts

    -- Kirim Notifikasi (Opsional, matikan jika mengganggu)
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Advertisement',
            text = 'New Ad by ' .. LastAdName,
            icon = 'fas fa-ad',
            color = '#ff8f1a',
            timeout = 2500,
        },
    })

    -- Refresh List di HP
    SendNUIMessage({
        action = 'RefreshAdverts',
        Adverts = PhoneData.Adverts
    })
end)

-- Event saat iklan dihapus
RegisterNetEvent('qb-phone:client:UpdateAdvertsDel', function(NewAdverts)
    PhoneData.Adverts = NewAdverts
    SendNUIMessage({
        action = 'RefreshAdverts',
        Adverts = PhoneData.Adverts
    })
end)

RegisterNetEvent('qb-phone:client:BillingEmail', function(data, paid, name)
    if paid then
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = 'Billing Department',
            subject = 'Invoice Paid',
            message = 'Invoice Has Been Paid From ' .. name .. ' In The Amount Of $' .. data.amount,
        })
    else
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = 'Billing Department',
            subject = 'Invoice Declined',
            message = 'Invoice Has Been Declined From ' .. name .. ' In The Amount Of $' .. data.amount,
        })
    end
end)

RegisterNetEvent('qb-phone:client:CancelCall', function()
    if PhoneData.CallData.CallType == 'ongoing' then
        SendNUIMessage({
            action = 'CancelOngoingCall'
        })
        exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
    end
    PhoneData.CallData.CallType = nil
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = {}

    if not PhoneData.isOpen then
        StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
        deletePhone()
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    end

    TriggerServerEvent('qb-phone:server:SetCallState', false)

    if not PhoneData.isOpen then
        SendNUIMessage({
            action = 'PhoneNotification',
            NotifyData = {
                title = 'Phone',
                content = 'The call has been ended',
                icon = 'fas fa-phone',
                timeout = 3500,
                color = '#e84118',
            },
        })
    else
        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Phone',
                text = 'The call has been ended',
                icon = 'fas fa-phone',
                color = '#e84118',
            },
        })

        SendNUIMessage({
            action = 'SetupHomeCall',
            CallData = PhoneData.CallData,
        })

        SendNUIMessage({
            action = 'CancelOutgoingCall',
        })
    end
end)

RegisterNetEvent('qb-phone:client:GetCalled', function(CallerNumber, CallId, AnonymousCall)
    local RepeatCount = 0
    local CallData = {
        number = CallerNumber,
        name = IsNumberInContacts(CallerNumber),
        anonymous = AnonymousCall
    }

    if AnonymousCall then
        CallData.name = 'Anonymous'
    end

    PhoneData.CallData.CallType = 'incoming'
    PhoneData.CallData.InCall = true
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = CallData
    PhoneData.CallData.CallId = CallId

    TriggerServerEvent('qb-phone:server:SetCallState', true)

    SendNUIMessage({
        action = 'SetupHomeCall',
        CallData = PhoneData.CallData,
    })

    for _ = 1, Config.CallRepeats + 1, 1 do
        if not PhoneData.CallData.AnsweredCall then
            if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                if PhoneData.CallData.InCall then
                    ESX.TriggerServerCallback('qb-phone:server:HasPhone', function(HasPhone)
                        if HasPhone then
                            RepeatCount = RepeatCount + 1
                            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'ringing', 0.2)

                            if not PhoneData.isOpen then
                                SendNUIMessage({
                                    action = 'IncomingCallAlert',
                                    CallData = PhoneData.CallData.TargetData,
                                    Canceled = false,
                                    AnonymousCall = AnonymousCall,
                                })
                            end
                        end
                    end)
                else
                    SendNUIMessage({
                        action = 'IncomingCallAlert',
                        CallData = PhoneData.CallData.TargetData,
                        Canceled = true,
                        AnonymousCall = AnonymousCall,
                    })
                    TriggerServerEvent('qb-phone:server:AddRecentCall', 'missed', CallData)
                    break
                end
                Wait(Config.RepeatTimeout)
            else
                SendNUIMessage({
                    action = 'IncomingCallAlert',
                    CallData = PhoneData.CallData.TargetData,
                    Canceled = true,
                    AnonymousCall = AnonymousCall,
                })
                TriggerServerEvent('qb-phone:server:AddRecentCall', 'missed', CallData)
                break
            end
        else
            TriggerServerEvent('qb-phone:server:AddRecentCall', 'missed', CallData)
            break
        end
    end
end)

RegisterNetEvent('qb-phone:client:UpdateMessages', function(ChatMessages, SenderNumber, New)
    local NumberKey = GetKeyByNumber(SenderNumber)
    -- Perlu identifier custom
    local myPhone = "000000"
    if PhoneData.PlayerData and PhoneData.PlayerData.charinfo then
         myPhone = PhoneData.PlayerData.charinfo.phone 
    end

    if New then
        PhoneData.Chats[#PhoneData.Chats + 1] = {
            name = IsNumberInContacts(SenderNumber),
            number = SenderNumber,
            messages = {},
        }

        NumberKey = GetKeyByNumber(SenderNumber)

        PhoneData.Chats[NumberKey] = {
            name = IsNumberInContacts(SenderNumber),
            number = SenderNumber,
            messages = ChatMessages
        }

        if PhoneData.Chats[NumberKey].Unread ~= nil then
            PhoneData.Chats[NumberKey].Unread = PhoneData.Chats[NumberKey].Unread + 1
        else
            PhoneData.Chats[NumberKey].Unread = 1
        end

        if PhoneData.isOpen then
            if SenderNumber ~= myPhone then
                SendNUIMessage({
                    action = 'PhoneNotification',
                    PhoneNotify = {
                        title = 'Whatsapp',
                        text = 'New message from ' .. IsNumberInContacts(SenderNumber) .. '!',
                        icon = 'fab fa-whatsapp',
                        color = '#25D366',
                        timeout = 1500,
                    },
                })
            else
                SendNUIMessage({
                    action = 'PhoneNotification',
                    PhoneNotify = {
                        title = 'Whatsapp',
                        text = 'Messaged yourself',
                        icon = 'fab fa-whatsapp',
                        color = '#25D366',
                        timeout = 4000,
                    },
                })
            end

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Wait(100)
            ESX.TriggerServerCallback('qb-phone:server:GetContactPictures', function(Chats)
                SendNUIMessage({
                    action = 'UpdateChat',
                    chatData = Chats[GetKeyByNumber(SenderNumber)],
                    chatNumber = SenderNumber,
                    Chats = Chats,
                })
            end, PhoneData.Chats)
        else
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'Whatsapp',
                    text = 'New message from ' .. IsNumberInContacts(SenderNumber) .. '!',
                    icon = 'fab fa-whatsapp',
                    color = '#25D366',
                    timeout = 3500,
                },
            })
            Config.PhoneApplications['whatsapp'].Alerts = Config.PhoneApplications['whatsapp'].Alerts + 1
            TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'whatsapp')
        end
    else
        PhoneData.Chats[NumberKey].messages = ChatMessages

        if PhoneData.Chats[NumberKey].Unread ~= nil then
            PhoneData.Chats[NumberKey].Unread = PhoneData.Chats[NumberKey].Unread + 1
        else
            PhoneData.Chats[NumberKey].Unread = 1
        end

        if PhoneData.isOpen then
            if SenderNumber ~= myPhone then
                SendNUIMessage({
                    action = 'PhoneNotification',
                    PhoneNotify = {
                        title = 'Whatsapp',
                        text = 'New message from ' .. IsNumberInContacts(SenderNumber) .. '!',
                        icon = 'fab fa-whatsapp',
                        color = '#25D366',
                        timeout = 1500,
                    },
                })
            else
                SendNUIMessage({
                    action = 'PhoneNotification',
                    PhoneNotify = {
                        title = 'Whatsapp',
                        text = 'Messaged yourself',
                        icon = 'fab fa-whatsapp',
                        color = '#25D366',
                        timeout = 4000,
                    },
                })
            end

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Wait(100)
            ESX.TriggerServerCallback('qb-phone:server:GetContactPictures', function(Chats)
                SendNUIMessage({
                    action = 'UpdateChat',
                    chatData = Chats[GetKeyByNumber(SenderNumber)],
                    chatNumber = SenderNumber,
                    Chats = Chats,
                })
            end, PhoneData.Chats)
        else
            SendNUIMessage({
                action = 'PhoneNotification',
                PhoneNotify = {
                    title = 'Whatsapp',
                    text = 'New message from ' .. IsNumberInContacts(SenderNumber) .. '!',
                    icon = 'fab fa-whatsapp',
                    color = '#25D366',
                    timeout = 3500,
                },
            })

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Config.PhoneApplications['whatsapp'].Alerts = Config.PhoneApplications['whatsapp'].Alerts + 1
            TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'whatsapp')
        end
    end
end)

RegisterNetEvent('qb-phone:client:RemoveBankMoney', function(amount)
    if amount > 0 then
        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Bank',
                text = '$' .. amount .. ' has been removed from your balance!',
                icon = 'fas fa-university',
                color = '#ff002f',
                timeout = 3500,
            },
        })
    end
end)

RegisterNetEvent('qb-phone:RefreshPhone', function()
    LoadPhone()
    SetTimeout(250, function()
        SendNUIMessage({
            action = 'RefreshAlerts',
            AppData = Config.PhoneApplications,
        })
    end)
end)

RegisterNetEvent('qb-phone:client:AddTransaction', function(_, _, Message, Title)
    local Data = {
        TransactionTitle = Title,
        TransactionMessage = Message,
    }
    PhoneData.CryptoTransactions[#PhoneData.CryptoTransactions + 1] = Data
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Crypto',
            text = Message,
            icon = 'fas fa-chart-pie',
            color = '#04b543',
            timeout = 1500,
        },
    })
    SendNUIMessage({
        action = 'UpdateTransactions',
        CryptoTransactions = PhoneData.CryptoTransactions
    })

    TriggerServerEvent('qb-phone:server:AddTransaction', Data)
end)

RegisterNetEvent('qb-phone:client:AddNewSuggestion', function(SuggestionData)
    PhoneData.SuggestedContacts[#PhoneData.SuggestedContacts + 1] = SuggestionData
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = 'Phone',
            text = 'You have a new suggested contact!',
            icon = 'fa fa-phone-alt',
            color = '#04b543',
            timeout = 1500,
        },
    })
    Config.PhoneApplications['phone'].Alerts = Config.PhoneApplications['phone'].Alerts + 1
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', 'phone', Config.PhoneApplications['phone'].Alerts)
end)

RegisterNetEvent('qb-phone:client:UpdateHashtags', function(Handle, msgData)
    if PhoneData.Hashtags[Handle] ~= nil then
        PhoneData.Hashtags[Handle].messages[#PhoneData.Hashtags[Handle].messages + 1] = msgData
    else
        PhoneData.Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        PhoneData.Hashtags[Handle].messages[#PhoneData.Hashtags[Handle].messages + 1] = msgData
    end

    SendNUIMessage({
        action = 'UpdateHashtags',
        Hashtags = PhoneData.Hashtags,
    })
end)

RegisterNetEvent('qb-phone:client:AnswerCall', function()
    if (PhoneData.CallData.CallType == 'incoming' or PhoneData.CallData.CallType == 'outgoing') and PhoneData.CallData.InCall and not PhoneData.CallData.AnsweredCall then
        PhoneData.CallData.CallType = 'ongoing'
        PhoneData.CallData.AnsweredCall = true
        PhoneData.CallData.CallTime = 0

        SendNUIMessage({ action = 'AnswerCall', CallData = PhoneData.CallData })
        SendNUIMessage({ action = 'SetupHomeCall', CallData = PhoneData.CallData })

        TriggerServerEvent('qb-phone:server:SetCallState', true)

        if PhoneData.isOpen then
            DoPhoneAnimation('cellphone_text_to_call')
        else
            DoPhoneAnimation('cellphone_call_listen_base')
        end

        CreateThread(function()
            while true do
                if PhoneData.CallData.AnsweredCall then
                    PhoneData.CallData.CallTime = PhoneData.CallData.CallTime + 1
                    SendNUIMessage({
                        action = 'UpdateCallTime',
                        Time = PhoneData.CallData.CallTime,
                        Name = PhoneData.CallData.TargetData.name,
                    })
                else
                    break
                end

                Wait(1000)
            end
        end)
        exports['pma-voice']:addPlayerToCall(PhoneData.CallData.CallId)
    else
        PhoneData.CallData.InCall = false
        PhoneData.CallData.CallType = nil
        PhoneData.CallData.AnsweredCall = false

        SendNUIMessage({
            action = 'PhoneNotification',
            PhoneNotify = {
                title = 'Phone',
                text = "You don't have a incoming call...",
                icon = 'fas fa-phone',
                color = '#e84118',
            },
        })
    end
end)

RegisterNetEvent('qb-phone:client:addPoliceAlert', function(alertData)
    PlayerJob = ESX.GetPlayerData().job
    if PlayerJob.name == 'police' then
        SendNUIMessage({
            action = 'AddPoliceAlert',
            alert = alertData,
        })
    end
end)

RegisterNetEvent('qb-phone:client:GiveContactDetails', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local PlayerId = GetPlayerServerId(player)
        TriggerServerEvent('qb-phone:server:GiveContactDetails', PlayerId)
    else
        ESX.ShowNotification('No one nearby!')
    end
end)

RegisterNetEvent('qb-phone:client:UpdateLapraces', function()
    SendNUIMessage({
        action = 'UpdateRacingApp',
    })
end)

RegisterNetEvent('qb-phone:client:GetMentioned', function(TweetMessage, AppAlerts)
    Config.PhoneApplications['twitter'].Alerts = AppAlerts
    SendNUIMessage({ action = 'PhoneNotification', PhoneNotify = { title = 'You have been mentioned in a Tweet!', text = TweetMessage.message, icon = 'fab fa-twitter', color = '#1DA1F2', }, })
    TweetMessage = { firstName = TweetMessage.firstName, lastName = TweetMessage.lastName, message = escape_str(TweetMessage.message), time = TweetMessage.time, picture = TweetMessage.picture }
    PhoneData.MentionedTweets[#PhoneData.MentionedTweets + 1] = TweetMessage
    SendNUIMessage({ action = 'RefreshAppAlerts', AppData = Config.PhoneApplications })
    SendNUIMessage({ action = 'UpdateMentionedTweets', Tweets = PhoneData.MentionedTweets })
end)

RegisterNetEvent('qb-phone:refreshImages', function(images)
    PhoneData.Images = images
end)

RegisterNetEvent('qb-phone:client:CustomNotification', function(title, text, icon, color, timeout) -- Send a PhoneNotification to the phone from anywhere
    SendNUIMessage({
        action = 'PhoneNotification',
        PhoneNotify = {
            title = title,
            text = text,
            icon = icon,
            color = color,
            timeout = timeout,
        },
    })
end)

-- Tambahkan ini di client.lua
RegisterNetEvent('qb-phone:client:UpdateMetaData', function(newMetaData)
    -- 1. Update variable lokal
    PhoneData.MetaData = newMetaData
    
    -- 2. Update data PlayerData
    local PlayerData = ESX.GetPlayerData()
    PlayerData.metadata = newMetaData -- Sync ke ESX PlayerData jika perlu

    -- 3. Kirim data baru ke Javascript (NUI)
    SendNUIMessage({
        action = 'UpdateMetaData', -- Pastikan JS kamu menangani action ini
        MetaData = PhoneData.MetaData
    })
    
    -- Opsional: Force reload background/frame di UI
    SendNUIMessage({
        action = 'LoadPhoneData',
        PhoneData = PhoneData,
        PlayerData = PhoneData.PlayerData,
        PlayerJob = PhoneData.PlayerData.job,
        applications = Config.PhoneApplications,
        PlayerId = GetPlayerServerId(PlayerId())
    })
end)

-- Threads

CreateThread(function()
    Wait(500)
    LoadPhone()
end)

CreateThread(function()
    while true do
        if PhoneData.isOpen then
            SendNUIMessage({
                action = 'UpdateTime',
                InGameTime = CalculateTimeToDisplay(),
            })
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        if ESX.IsPlayerLoaded() then
            ESX.TriggerServerCallback('qb-phone:server:GetPhoneData', function(pData)
                if pData.PlayerContacts ~= nil and next(pData.PlayerContacts) ~= nil then
                    PhoneData.Contacts = pData.PlayerContacts
                end
                SendNUIMessage({
                    action = 'RefreshContacts',
                    Contacts = PhoneData.Contacts
                })
            end)
        end
    end
end)