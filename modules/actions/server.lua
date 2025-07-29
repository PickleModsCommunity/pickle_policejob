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
    end
    local eventData = data
    eventData.source = source
    eventData.target = targetPlayer
    TriggerClientEvent("pickle_policejob:actions:detainment", source, eventData)
    TriggerClientEvent("pickle_policejob:actions:detainment", targetPlayer, eventData)
end)