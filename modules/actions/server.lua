local HandcuffedPlayers = {}
local DraggedPlayers = {}
local StabSticks = {}
local ObjectPlacement = {}

function CreateStabSticks(sticks)
    local id
    repeat
        id = math.random(1, 1000000)
    until not StabSticks[id]
    StabSticks[id] = {
        sticks = {},
    }
    for _, stick in ipairs(sticks) do
        table.insert(StabSticks[id].sticks, {
            coords = stick.coords,
            rotation = stick.rotation,
        })
    end
    TriggerClientEvent("pickle_policejob:actions:createStabSticks", -1, id, StabSticks[id])
end

function DeleteStabSticks(id)
    StabSticks[id] = nil
    TriggerClientEvent("pickle_policejob:actions:deleteStabSticks", -1, id)
end

RegisterNetEvent("pickle_policejob:actions:detainment", function(targetPlayer, data)
    local source = source
    if data.eventType ~= "stopDrag" and not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    if data.eventType == "toggleHandcuffs" then
        if DraggedPlayers[targetPlayer] then
            ShowNotification(source, _L("stop_dragging_first"))
            return
        end
        HandcuffedPlayers[targetPlayer] = not HandcuffedPlayers[targetPlayer]
        data.cuffed = HandcuffedPlayers[targetPlayer]
    elseif data.eventType == "toggleDrag" then
        if not HandcuffedPlayers[targetPlayer] then
            ShowNotification(source, _L("player_not_handcuffed"))
            return
        end
        if DraggedPlayers[targetPlayer] then
            DraggedPlayers[targetPlayer] = nil
        else
            DraggedPlayers[targetPlayer] = source
        end
        data.dragged = DraggedPlayers[targetPlayer]
    elseif data.eventType == "stopDrag" then
        data.eventType = "toggleDrag"
        source = tonumber(DraggedPlayers[targetPlayer])
        targetPlayer = tonumber(targetPlayer)
        DraggedPlayers[targetPlayer] = nil
        data.dragged = DraggedPlayers[targetPlayer]
    elseif data.eventType == "toggleVehicleSeat" then
        if not HandcuffedPlayers[targetPlayer] then
            ShowNotification(source, _L("player_not_handcuffed"))
            return
        end
        if DraggedPlayers[targetPlayer] then
            local cancelEvent = {eventType = "toggleDrag", dragged = false, source = DraggedPlayers[targetPlayer], target = targetPlayer}
            TriggerClientEvent("pickle_policejob:actions:detainment", DraggedPlayers[targetPlayer], cancelEvent)
            TriggerClientEvent("pickle_policejob:actions:detainment", targetPlayer, cancelEvent)
            SetTimeout(100, function()
                DraggedPlayers[targetPlayer] = nil
                local eventData = {eventType = "toggleVehicleSeat", source = source, target = targetPlayer, seatId = data.seatId, netId = data.netId}
                TriggerClientEvent("pickle_policejob:actions:detainment", source, eventData)
                TriggerClientEvent("pickle_policejob:actions:detainment", targetPlayer, eventData)
            end)
            return
        end
        local vehicle = NetworkGetEntityFromNetworkId(data.netId)
        if not vehicle then return ShowNotification(source, _L("no_vehicle_nearby")) end
    end
    local eventData = data
    eventData.source = source
    eventData.target = targetPlayer
    TriggerClientEvent("pickle_policejob:actions:detainment", source, eventData)
    TriggerClientEvent("pickle_policejob:actions:detainment", targetPlayer, eventData)
end)

RegisterNetEvent("pickle_policejob:actions:placeStabSticks", function(sticks)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    if #sticks < 1 then return ShowNotification(source, _L("no_sticks_placed")) end
    CreateStabSticks(sticks)
end)

RegisterNetEvent("pickle_policejob:actions:deleteStabSticks", function(id)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    DeleteStabSticks(id)
end)

RegisterNetEvent("pickle_policejob:actions:placeObject", function(data)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    if not Config.ObjectPlacement.props[data.index] then return ShowNotification(source, _L("invalid_object")) end
    local id
    repeat
        id = math.random(1, 1000000)
    until not ObjectPlacement[id]
    ObjectPlacement[id] = {
        index = data.index,
        coords = data.coords,
        rotation = data.rotation,
    }
    TriggerClientEvent("pickle_policejob:actions:placeObject", -1, id, ObjectPlacement[id])
end)

RegisterNetEvent("pickle_policejob:actions:deleteObject", function(id)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    ObjectPlacement[id] = nil
    TriggerClientEvent("pickle_policejob:actions:deleteObject", -1, id)
end)

RegisterNetEvent("pickle_policejob:actions:requestFingerprint", function(targetId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    ShowNotification(source, _L("sent_fingerprint_scan_request", GetPlayerCharacterName(targetId)))
    TriggerClientEvent("pickle_policejob:actions:requestFingerprint", targetId, source)
end)

RegisterNetEvent("pickle_policejob:actions:grantFingerprintConsent", function(requestId)
    local source = source
    TriggerClientEvent("pickle_policejob:actions:requestFingerprint", requestId, requestId, GetPlayerDNA(source), source)
end)

CreateThread(function()
    Wait(2000)
    CreateStabSticks({
        {
            coords = vector3(2220.4922, 3812.4099, 32.8988),
            rotation = vector3(0.0, 0.0, 118.8556),
        },
    })
end)