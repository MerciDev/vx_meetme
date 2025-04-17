local QBCore = exports['qb-core']:GetCoreObject()
local knownPlayers = {}
local activeRequest = false
Settings = {
    inspectMessage = "",
    autoMessage = "",
    messageCooldown = 5,
    messageRange = 20
}
Editing = false

RegisterCommand('config_meetme', function()
    lib.showMenu('meetme_main')
end, false)

local function updateKnownPlayers()
    QBCore.Functions.TriggerCallback('meetme:getKnownPlayers', function(result)
        knownPlayers = result or {}
    end)
end

local function GetTargetPlayerData(entity)
    local targetId = NetworkGetPlayerIndexFromPed(entity)
    if targetId == -1 then return nil end
    return GetPlayerServerId(targetId)
end

local playerOptions = {
    {
        name = "ox_target:meetme",
        icon = "fa-solid fa-eye",
        label = _('target.inspect_person'),
        onSelect = function(data)
            local targetId = GetTargetPlayerData(data.entity)
            if not targetId or targetId == 0 then
                lib.notify({
                    title = 'Error',
                    description = _('notify.no_identified'),
                    type = 'error',
                    position = 'top'
                })
                return
            end
            LoadSettings()
            QBCore.Functions.TriggerCallback('meetme:getSettingsFromPlayer', function(playerSettings)
                if playerSettings then
                    if playerSettings.inspectMessage == '' then playerSettings.inspectMessage = _('notify.no_inspect_message') end
                    local alert = lib.alertDialog({
                        header = _('notify.inspect'),
                        content = playerSettings.inspectMessage or _('notify.no_inspect_message'),
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = _('notify.close'),
                            cancel = _('notify.close'),
                        },
                        size = 'md'
                    })
                else
                    print("No se encontraron settings para el jugador.")
                end
            end, targetId)
        end,
        canInteract = function(entity, distance, data)
            if not IsPedAPlayer(entity) then return false end
            if entity == PlayerPedId() then return false end

            local targetId = GetTargetPlayerData(entity)
            if not targetId or targetId == 0 then return false end

            return not knownPlayers[targetId]
        end
    },
    {
        name = "ox_target:meetme",
        icon = "fa-solid fa-handshake",
        label = _('target.meet_person'),
        onSelect = function(data)
            local targetId = GetTargetPlayerData(data.entity)
            if not targetId or targetId == 0 then
                lib.notify({
                    title = 'Error',
                    description = _('notify.no_identified'),
                    type = 'error',
                    position = 'top'
                })
                return
            end

            lib.notify({
                title = _('notify.request_sent.title'),
                description = _('notify.request_sent.description', targetId),
                type = 'success',
                position = 'top'
            })

            TriggerServerEvent('meetme:requestMeeting', targetId)
        end,
        canInteract = function(entity, distance, data)
            if not IsPedAPlayer(entity) then return false end
            if entity == PlayerPedId() then return false end

            local targetId = GetTargetPlayerData(entity)
            if not targetId or targetId == 0 then return false end

            return not knownPlayers[targetId]
        end
    }
}

exports.ox_target:addGlobalPlayer(playerOptions)

RegisterNetEvent('meetme:receiveRequest')
AddEventHandler('meetme:receiveRequest', function(requesterName, requesterId)
    if activeRequest then return end
    activeRequest = true

    local alert = lib.alertDialog({
        header = _('notify.receiveRequest.header'),
        content = _('notify.receiveRequest.content', requesterName),
        centered = true,
        cancel = true,
        labels = {
            confirm = _('notify.confirm'),
            cancel = _('notify.cancel')
        },
        size = 'md'
    })

    local showLastname
    if Config.lastname then
        showLastname = lib.alertDialog({
            header = _('notify.showLastname.header'),
            content = _('notify.showLastname.content', requesterName),
            centered = true,
            cancel = true,
            labels = {
                confirm = _('notify.confirm'),
                cancel = _('notify.cancel')
            },
            size = 'md'
        })
    end

    activeRequest = false

    if alert == 'confirm' then
        TriggerServerEvent('meetme:acceptRequest', requesterId, showLastname == 'confirm' or false)
    elseif alert == 'cancel' then
        TriggerServerEvent('meetme:rejectRequest', requesterId)
        lib.notify({
            title = _('notify.rejectRequest.title'),
            description = _('notify.rejectRequest.description', requesterName),
            type = 'error',
            position = 'top'
        })
    end
end)

RegisterNetEvent('meetme:playerKnowsYou')
AddEventHandler('meetme:playerKnowsYou', function(playerName)
    lib.notify({
        title = _('notify.playerKnowsYou.title'),
        description = _('notify.playerKnowsYou.title', playerName),
        type = 'success',
        position = 'top'
    })
end)

RegisterNetEvent('meetme:updateKnownPlayers')
AddEventHandler('meetme:updateKnownPlayers', function(newList)
    knownPlayers = newList or {}
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    updateKnownPlayers()
end)

exports('DoesPlayerKnow', function(targetServerId, cb)
    QBCore.Functions.TriggerCallback('vx_meetme:doesPlayerKnow', function(result)
        cb(result)
    end, targetServerId)
end)

exports('GetKnownPlayerName', function(targetServerId, cb)
    QBCore.Functions.TriggerCallback('vx_meetme:getKnownPlayerName', function(result)
        cb(result)
    end, targetServerId)
end)

function UpdatePeopleList()
    local options = {}
    local knownList = QBCore.Functions.TriggerCallback('meetme:getClientContacts', {})
    local peopleList = {}
    local idsList = {}

    if next(knownList) then
        for id, name in pairs(knownList) do
            table.insert(peopleList, name)
            table.insert(idsList, id)
        end
    end

    if #peopleList > 0 then
        for _, name in ipairs(peopleList) do
            table.insert(options, {
                label = name,
                icon = 'user',
                args = { id = idsList[_], name = name }
            })
        end
    else
        table.insert(options, {
            label = _('meetme_list.no_contacts.label'),
            description = _('meetme_list.no_contacts.description'),
            icon = 'user-xmark',
            disabled = true
        })
    end

    lib.setMenuOptions('meetme_list', options)
end

UpdatePeopleList()

function LoadSettings()
    QBCore.Functions.TriggerCallback('meetme:getSettings', function(serverSettings)
        if serverSettings then
            for k, v in pairs(serverSettings) do
                Settings[k] = v
            end
        else
            TriggerServerEvent('meetme:saveSettings', Settings)
        end
    end)
end

Citizen.CreateThread(function()
    LoadSettings()
    local lastMessageTime = GetGameTimer()
    while true do
        Citizen.Wait(1000)
        local currentTime = GetGameTimer()
        local elapsedTime = (currentTime - lastMessageTime) / 1000
        if elapsedTime >= (Settings.messageCooldown * 60) then
            elapsedTime = 0
            if Settings.autoMessage ~= '' then
                ExecuteCommand('rangedo ' .. Settings.messageRange .. ' ' .. Settings.autoMessage)
                lastMessageTime = GetGameTimer()
            end
            if not Editing then LoadSettings() end
        end
    end
end)

RegisterNetEvent('vx_meetme:sendDoRange', function(playerId, title, message, color, range)
	local source = PlayerId()
	local target = GetPlayerFromServerId(playerId)

	if target ~= -1 then
		local sourcePed, targetPed = PlayerPedId(), GetPlayerPed(target)
		local sourceCoords, targetCoords = GetEntityCoords(sourcePed), GetEntityCoords(targetPed)

		if targetPed == source or #(sourceCoords - targetCoords) < range then
			local playerData = QBCore.Functions.GetPlayerData()
			local sourceName = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname

			exports['vx_meetme']:DoesPlayerKnow(playerId, function(knowsPlayer)
				if knowsPlayer or (tonumber(sourcePed) == tonumber(targetPed)) then
					exports['vx_meetme']:GetKnownPlayerName(playerId, function(playerName)
						TriggerEvent('chat:addMessage', {
							template = '<div style="'..
								'font-weight: bold;'..
								'margin-bottom: 3px;'..
								'width: fit-content;'..
								'max-width: 80%;'..
								'padding: 4px 12px;'..
								'background-color: rgba(0, 40, 80, 0.7);'..
								'border-radius: 6px;'..
								'border-left: 4px solid rgba(50, 150, 255, 0.9);'..
								'box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);'..
								'color: #cce5ff;'..
								'text-shadow: 0 1px 1px rgba(0, 0, 0, 0.3);'..
							'">'..
								'<span style="'..
									'display: inline-block;'..
									'font-weight: 800;'..
									'color: #99ccff;'..
									'margin-right: 5px;'..
								'">'..
									'{0}'..
								'</span>'..
								'<span style="'..
									'color: #ffffff;'..
									'font-weight: normal;'..
								'">'..
									message..
								'</span>'..
							'</div>',
							args = { "[DO] - "..(playerName or sourceName) }
						})
					end)
				else
					TriggerEvent('chat:addMessage', {
						template = '<div style="'..
							'font-weight: bold;'..
							'margin-bottom: 3px;'..
							'width: fit-content;'..
							'max-width: 80%;'..
							'padding: 4px 12px;'..
							'background-color: rgba(0, 40, 80, 0.7);'..
							'border-radius: 6px;'..
							'border-left: 4px solid rgba(50, 150, 255, 0.9);'..
							'box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);'..
							'color: #cce5ff;'..
							'text-shadow: 0 1px 1px rgba(0, 0, 0, 0.3);'..
						'">'..
							'<span style="'..
								'display: inline-block;'..
								'font-weight: 800;'..
								'color: #99ccff;'..
								'margin-right: 5px;'..
							'">'..
								'{0}'..
							'</span>'..
							'<span style="'..
								'color: #ffffff;'..
								'font-weight: normal;'..
							'">'..
								message..
							'</span>'..
						'</div>',
						args = { "[DO] - "..playerId }
					})
				end
			end)
		end
	end
end)