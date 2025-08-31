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

lib.callback.register("pickle_policejob:actions:getIDCard", function(source, targetId)
    local target = GetPlayerCharacterName(targetId)
    local dob = GetPlayerDateOfBirth(targetId) or "Unknown"
    local gender = GetPlayerGender(targetId) or "Unknown"
    local job = (GetPlayerJob(targetId)?.label or GetPlayerJob(targetId)?.name) or "Unknown"
    return {name = target, dob = dob, gender = gender, job = job}
end)

lib.callback.register("pickle_policejob:actions:getVehicleInfo", function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end
    local plate = GetVehicleNumberPlateText(vehicle) or "UNKNOWN"
    local data = GetOwnedVehicleFromPlate(plate) or {owner = "UNKNOWN"}
    local owner = GetPlayerCharacterName(data.owner)
    if owner == "ERR_UNK_NAME" then owner = "UNKNOWN" end
    return {plate = plate, owner = owner, identifier = data.owner}
end)

RegisterNetEvent("pickle_policejob:actions:lockpickVehicle", function(netId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    ShowNotification(source, _L("lockpicked_vehicle"))
    TriggerClientEvent("pickle_policejob:actions:lockpickVehicle", -1, netId)
end)

RegisterNetEvent("pickle_policejob:actions:impoundVehicle", function(netId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    if not NetworkDoesNetworkIdExist(netId) then return ShowNotification(source, _L("no_vehicle_nearby")) end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then return ShowNotification(source, _L("no_vehicle_nearby")) end
    ImpoundVehiclePlate(GetVehicleNumberPlateText(vehicle))
    ShowNotification(source, _L("vehicle_impounded", GetVehicleNumberPlateText(vehicle)))
    DeleteVehicle(vehicle)
end)

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

RegisterNetEvent("pickle_policejob:actions:uncuffSelf", function()
    local source = source
    HandcuffedPlayers[source] = nil
    TriggerClientEvent("pickle_policejob:actions:detainment", source, {
        eventType = "toggleHandcuffs",
        cuffStyle = "back",
        dragged = false,
        source = 0,
        target = source,
        instant = true,
    })
end)

RegisterNetEvent("pickle_policejob:actions:uncuffOther", function(targetId)
    local source = source
    print("A")
    if not HandcuffedPlayers[targetId] then return ShowNotification(source, _L("player_not_handcuffed")) end
    HandcuffedPlayers[targetId] = nil
    print("B")
    TriggerClientEvent("pickle_policejob:actions:detainment", targetId, {
        eventType = "toggleHandcuffs",
        cuffStyle = "back",
        dragged = false,
        source = 0,
        target = targetId,
        instant = true,
    })
end)

if Config.Handcuffs.lockpickItem then
    RegisterUsableItem(Config.Handcuffs.lockpickItem, function(source)
        local source = source
        local targetId
        local closestDistance = 100
        for _, player in ipairs(GetPlayers()) do
            if tonumber(player) ~= source then 
                local ped = GetPlayerPed(player)
                local distance = #(GetEntityCoords(ped) - GetEntityCoords(GetPlayerPed(source)))
                if distance < closestDistance then
                    closestDistance = distance
                    targetId = tonumber(player)
                end
            end
        end
        if closestDistance > 3.0 or not targetId or not HandcuffedPlayers[targetId] then return ShowNotification(source, _L("no_player_nearby")) end
        if Config.Handcuffs.lockpickRemoveChance > 0 and math.random(1, 100) <= Config.Handcuffs.lockpickRemoveChance then
            Inventory.RemoveItem(source, Config.Handcuffs.lockpickItem, 1)
        end
        TriggerClientEvent("pickle_policejob:actions:uncuffOther", source, targetId)
    end)
end

CreateThread(function()
    Wait(2000)
    CreateStabSticks({
        {
            coords = vector3(2220.4922, 3812.4099, 32.8988),
            rotation = vector3(0.0, 0.0, 118.8556),
        },
    })
end)