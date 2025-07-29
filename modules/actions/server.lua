local HandcuffedPlayers = {}
local DraggedPlayers = {}

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