local QBCore = exports['qb-core']:GetCoreObject()
local pendingRequests = {}

local function getContactsList(citizenid)
    local result = MySQL.scalar.await('SELECT known_people FROM meetme_users WHERE citizenid = ?', { citizenid })
    if not result then return {} end
    print(json.encode(result))
    return json.decode(result) or {}
end

local function saveContactsList(citizenid, contacts)
    local jsonData = json.encode(contacts)

    return MySQL.insert.await(
        'INSERT INTO meetme_users (citizenid, known_people) VALUES (?, ?) ON DUPLICATE KEY UPDATE known_people = ?',
        { citizenid, jsonData, jsonData })
end

QBCore.Functions.CreateCallback('meetme:getKnownPlayers', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    cb(contacts)
end)

local function DoesPlayerKnow(source, targetServerId)
    local Player = QBCore.Functions.GetPlayer(source)
    local Target = QBCore.Functions.GetPlayer(targetServerId)

    if not Player or not Target then return false end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    return contacts[Target.PlayerData.citizenid] ~= nil
end

local function GetKnownPlayerName(source, targetServerId)
    local Player = QBCore.Functions.GetPlayer(source)
    local Target = QBCore.Functions.GetPlayer(targetServerId)

    if not Player or not Target then return false end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    return contacts[Target.PlayerData.citizenid] or false
end

QBCore.Functions.CreateCallback('vx_meetme:doesPlayerKnow', function(source, cb, targetServerId)
    cb(DoesPlayerKnow(source, targetServerId))
end)

QBCore.Functions.CreateCallback('vx_meetme:getKnownPlayerName', function(source, cb, targetServerId)
    cb(GetKnownPlayerName(source, targetServerId))
end)

RegisterNetEvent('meetme:requestMeeting', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    if not Player or not Target or src == targetId then return end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    if contacts[Target.PlayerData.citizenid] then
        TriggerClientEvent('QBCore:Notify', src, _('notify.already_known', Target.PlayerData.charinfo.firstname), 'error')
        return
    end

    pendingRequests[src] = {
        target = targetId,
        sourceName = Player.PlayerData.charinfo.firstname ..
            (Config.lastname and ' ' .. Player.PlayerData.charinfo.lastname or ''),
        sourceCitizenid = Player.PlayerData.citizenid
    }

    TriggerClientEvent('meetme:receiveRequest', targetId,
        Player.PlayerData.charinfo.firstname,
        src
    )
    TriggerClientEvent('QBCore:Notify', src, _('notify.request_sent', Target.PlayerData.charinfo.firstname), 'success')
end)

RegisterNetEvent('meetme:acceptRequest', function(requesterId, saveLastName)
    local src = source
    local request = pendingRequests[requesterId]

    if not request or request.target ~= src then return end

    local Requester = QBCore.Functions.GetPlayer(requesterId)
    local Accepter = QBCore.Functions.GetPlayer(src)

    if not Requester or not Accepter then return end

    local requesterContacts = getContactsList(Requester.PlayerData.citizenid)
    print(saveLastName)
    print(((Config.lastname and saveLastName) and (' ' .. Accepter.PlayerData.charinfo.lastname) or ''))
    requesterContacts[Accepter.PlayerData.citizenid] = Accepter.PlayerData.charinfo.firstname ..
        ((Config.lastname and saveLastName) and (' ' .. Accepter.PlayerData.charinfo.lastname) or '')

    saveContactsList(Requester.PlayerData.citizenid, requesterContacts)

    TriggerClientEvent('meetme:updateKnownPlayers', requesterId)

    TriggerClientEvent('meetme:playerKnowsYou', src,
        Requester.PlayerData.charinfo.firstname ..
        ((Config.lastname and saveLastName) and (' ' .. Requester.PlayerData.charinfo.lastname) or ''))

    pendingRequests[requesterId] = nil
end)

RegisterNetEvent('meetme:rejectRequest', function(requesterId)
    local src = source
    local request = pendingRequests[requesterId]

    if request and request.target == src then
        TriggerClientEvent('QBCore:Notify', requesterId, _('notify.rejectRequest'), 'error')
        pendingRequests[requesterId] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if pendingRequests[src] then
        pendingRequests[src] = nil
    end
end)

QBCore.Functions.CreateCallback('meetme:getClientContacts', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    cb(contacts)
end)

RegisterNetEvent('meetme:requestContacts', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local contacts = getContactsList(Player.PlayerData.citizenid)
    TriggerClientEvent('meetme:receiveContacts', src, contacts)
end)

exports('DoesPlayerKnow', DoesPlayerKnow)
exports('GetKnownPlayerName', GetKnownPlayerName)

local function removeContact(citizenid, contactToRemove)
    local contacts = getContactsList(citizenid)
    if contacts[contactToRemove] then
        contacts[contactToRemove] = nil
        saveContactsList(citizenid, contacts)
        return true
    end
    return false
end

RegisterNetEvent('meetme:removeContact', function(targetCitizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if removeContact(Player.PlayerData.citizenid, targetCitizenid) then
        TriggerClientEvent('QBCore:Notify', src, _('notify.removeContact.success'), 'success')
        TriggerClientEvent('meetme:updateKnownPlayers', src)
    else
        TriggerClientEvent('QBCore:Notify', src, _('notify.removeContact.error'), 'error')
    end
end)

exports('RemoveContact', function(source, targetCitizenid)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return removeContact(Player.PlayerData.citizenid, targetCitizenid)
end)

local function saveUserSettings(citizenid, settings)
    local jsonData = json.encode(settings)
    return MySQL.update.await(
        'INSERT INTO meetme_users (citizenid, settings) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE settings = ?',
        { citizenid, jsonData, jsonData }
    )
end

local function getUserSettings(citizenid)
    local result = MySQL.scalar.await('SELECT settings FROM meetme_users WHERE citizenid = ?', { citizenid })
    if not result then
        return {
            inspectMessage = _('notify.no_inspect_message'),
            autoMessage = '',
            messageCooldown = 5,
            messageRange = 20
        }
    end
    return json.decode(result) or {}
end

QBCore.Functions.CreateCallback('meetme:getSettings', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    cb(getUserSettings(Player.PlayerData.citizenid))
end)

QBCore.Functions.CreateCallback('meetme:getSettingsFromPlayer', function(source, cb, targetId)
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        return cb(nil)
    end
    cb(getUserSettings(TargetPlayer.PlayerData.citizenid))
end)

RegisterNetEvent('meetme:saveSettings', function(settings)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    settings = {
        inspectMessage = tostring(settings.inspectMessage or '---'),
        autoMessage = tostring(settings.autoMessage or '---'),
        messageCooldown = tonumber(settings.messageCooldown) or 5,
        messageRange = tonumber(settings.messageRange) or 20
    }

    if saveUserSettings(Player.PlayerData.citizenid, settings) then
        TriggerClientEvent('QBCore:Notify', src, 'Ajustes guardados correctamente', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Error al guardar ajustes', 'error')
    end
end)

RegisterNetEvent('vx_meetme:sendAutoDO', function(targetId, message, range)
    local src = source

    if not QBCore.Functions.GetPlayer(src) or not QBCore.Functions.GetPlayer(targetId) then return end

    range = math.min(tonumber(range) or 3, 50)

    local cooldown = math.max(tonumber(Settings.messageCooldown) or 5, 1)

    TriggerClientEvent('qb_rpchat:sendDoRange', targetId, src, message, range)
end)

RegisterCommand('rangedo', function(source, args, raw)
    if source == 0 then
        print('vx_meetme: you can\'t use this command from rcon!')
        return
    end

    if #args < 2 then
        return
    end

    local range = tonumber(args[1])
    if not range or range <= 0 then
        return
    end

    table.remove(args, 1)
    local message = table.concat(args, ' ')

    local name = ''

    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end

    TriggerClientEvent('vx_meetme:sendDoRange', -1, source, name, message, { 255, 198, 0 }, range)
end, false)
