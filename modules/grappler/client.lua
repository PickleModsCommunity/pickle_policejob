local grappler = nil
local rope = nil
local GrapplerVehicles = {}
local LocalGrapplerVehicles = {}
local TARGET_OPTIONS = {
    {
        name = "pickle_policejob:grappler:remove",
        icon = Config.TargetIcons.grappler,
        label = _L("target_grappler_remove"),
        onSelect = function()
            local closestGrappler = nil
            local closestDistance = 100.0
            for vehicleNetId, grapplerData in pairs(GrapplerVehicles) do
                local grapplerCoords = GetOffsetFromEntityInWorldCoords(NetworkGetEntityFromNetworkId(vehicleNetId), grapplerData.grapplerOffset.x, grapplerData.grapplerOffset.y, grapplerData.grapplerOffset.z)
                local distance = #(GetEntityCoords(PlayerPedId()) - grapplerCoords)
                if distance < closestDistance then
                    closestGrappler = vehicleNetId
                    closestDistance = distance
                end
            end
            if closestDistance < 2.0 then
                if true or not IsPlayerOnDuty() then 
                    local ped = PlayerPedId()
                    TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 1.0, -1.0, -1, 0, 0, false, false, false)
                    local success = lib.skillCheck({'easy', 'medium', 'medium', 'medium'}, {'w', 'a', 's', 'd'})
                    ClearPedTasks(ped)
                    if not success then
                        ShowNotification(_L("failed_grappler_removal"))
                        return
                    end
                end
                ShowNotification(_L("grappler_removed"))
                TriggerServerEvent("pickle_policejob:grappler:remove", closestGrappler)
            end
        end,
    }
}
local WHEEL_BONES = {"wheel_lf", "wheel_rf", "wheel_lr", "wheel_rr", "wheel_lm", "wheel_rm"}
local GrapplerPlacement = nil

function StartGrapplerPlacement()
    local vehicle = GetNearestVehicle(10.0)
    if not vehicle then return end
    GrapplerPlacement = {
        vehicle = vehicle,
        boneId = nil,
        grapplerOffset = vector3(0.0, 2.55, 0.0),
    }
    FreezeEntityPosition(vehicle, true)
    local vehicleCoords = GetEntityCoords(vehicle)
    local coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 2.55, 0.0)
    local object = CreateProp(`grapplerropes`, coords.x, coords.y, coords.z, false, false, false)
    CreateThread(function()
        while GrapplerPlacement do
            DrawMarker(0, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100)
            Wait(0)
        end
    end)
    local result = StartGizmoEditor({
        entity = object,
        coords = coords,
        rotation = GetEntityRotation(vehicle),
        keepRotation = true,
    })
    if not result then 
        DeleteEntity(object)
        FreezeEntityPosition(vehicle, false)
        GrapplerPlacement = nil
        return
    end
    local position = result.position
    local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, position.x, position.y, position.z)
    DeleteEntity(object)
    FreezeEntityPosition(vehicle, false)
    TriggerServerEvent("pickle_policejob:grappler:attachToVehicle", VehToNet(vehicle), {
        grapplerOffset = offset,
    })
    GrapplerPlacement = nil
end

function RemoveVehicleGrappler(vehicleNetId)
    UnrenderVehicleGrappler(vehicleNetId)
    GrapplerVehicles[vehicleNetId] = nil
end

function UnrenderVehicleGrappler(vehicleNetId)
    if not LocalGrapplerVehicles[vehicleNetId] then return end
    DeleteEntity(LocalGrapplerVehicles[vehicleNetId].grappler)
    if LocalGrapplerVehicles[vehicleNetId].rope then
        DeleteRope(LocalGrapplerVehicles[vehicleNetId].rope)
        LocalGrapplerVehicles[vehicleNetId].rope = nil
    end
    LocalGrapplerVehicles[vehicleNetId] = nil
end

function RenderVehicleGrappler(vehicleNetId)
    local grapplerData = GrapplerVehicles[vehicleNetId]
    UnrenderVehicleGrappler(vehicleNetId)
    LocalGrapplerVehicles[vehicleNetId] = {
        rope = nil,
        grappler = nil,
    }
    local localGrappler = LocalGrapplerVehicles[vehicleNetId]
    if not grapplerData then return end
    local boneId = grapplerData.boneId
    if not NetworkDoesNetworkIdExist(vehicleNetId) then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local grapplerOffset = grapplerData.grapplerOffset
    local grapplerCoords = GetOffsetFromEntityInWorldCoords(vehicle, grapplerOffset.x, grapplerOffset.y, grapplerOffset.z)
    if grapplerData.targetNetId then
        if not NetworkDoesNetworkIdExist(grapplerData.targetNetId) then return end
        local targetVehicle = NetworkGetEntityFromNetworkId(grapplerData.targetNetId)
        if not DoesEntityExist(targetVehicle) then return end
        local targetCoords = GetWorldPositionOfEntityBone(targetVehicle, GetEntityBoneIndexByName(targetVehicle, boneId))
        SetRopesCreateNetworkWorldState(false)
        local ropeType = 0 -- Type of the rope (for example, 4 for normal rope)
        local ropeLength = 5.0 -- Length of the rope
        localGrappler.rope = AddRope(grapplerCoords.x, grapplerCoords.y, grapplerCoords.z, 0.0, 0.0, 0.0, ropeLength, ropeType, ropeLength, 0.1, 10.0, true, false, true, 1.0, false)
        if localGrappler.rope ~= -1 then
            AttachEntitiesToRope(localGrappler.rope, vehicle, targetVehicle, grapplerCoords.x, grapplerCoords.y, grapplerCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, ropeLength, false, false)
            ActivatePhysics(localGrappler.rope)
            RopeLoadTextures()
        end
        local wheelIndex = -1
        for i=1, #WHEEL_BONES do
            if boneId == WHEEL_BONES[i] then
                wheelIndex = i - 1
                break
            end
        end
        if wheelIndex ~= -1 then
            SetVehicleTyreBurst(targetVehicle, wheelIndex, false, Config.StabSticks.burstDamage)
        end
        localGrappler.grappler = CreateProp(`grapplernoropes`, grapplerCoords.x, grapplerCoords.y, grapplerCoords.z, false, false, false)
        AttachEntityToEntity(localGrappler.grappler, vehicle, GetEntityBoneIndexByName(vehicle, "chassis"), grapplerOffset.x, grapplerOffset.y, grapplerOffset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        RequestAnimDict("va_Grappler")
        while not HasAnimDictLoaded("va_Grappler") do
            Wait(0)
        end
        PlayEntityAnim(localGrappler.grappler, "grappler", "va_Grappler" , 1000.0, false, true, false, 1.0, 136704)
    else
        local grapplerOffset = grapplerData.grapplerOffset
        localGrappler.grappler = CreateProp(`grapplerropes`, 0.0, 0.0, 0.0, false, false, false)
        AttachEntityToEntity(localGrappler.grappler, vehicle, GetEntityBoneIndexByName(vehicle, "chassis"), grapplerOffset.x, grapplerOffset.y, grapplerOffset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        if grapplerData.deployed then
            RequestAnimDict("va_Grappler")
            while not HasAnimDictLoaded("va_Grappler") do
                Wait(0)
            end
            PlayEntityAnim(localGrappler.grappler, "grappler", "va_Grappler" , 1000.0, false, true, false, 0.0, 136704)
        end
    end
end

CreateThread(function()
    while true do
        local wait = 2500
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local netId = DoesEntityExist(vehicle) and VehToNet(vehicle) or -1
        local localGrappler = LocalGrapplerVehicles[netId]
        local grapplerData = GrapplerVehicles[netId]
        if localGrappler and grapplerData and not localGrappler.rope then
            wait = 0
            if grapplerData.deployed then
                local grapplerOffset = grapplerData.grapplerOffset
                local grapplerPosition = GetOffsetFromEntityInWorldCoords(vehicle, grapplerOffset.x, grapplerOffset.y, grapplerOffset.z)
                local closestTarget = nil
                local closestDistance = 100.0
                local pool = GetGamePool("CVehicle")
                for i=1, #pool do
                    local targetVehicle = pool[i]
                    if DoesEntityExist(targetVehicle) and targetVehicle ~= vehicle then
                        local distance = #(grapplerPosition - GetEntityCoords(targetVehicle))
                        if distance < closestDistance then
                            closestTarget = targetVehicle
                            closestDistance = distance
                        end
                    end
                end
                if closestDistance < 20.0 then
                    grapplerPosition = GetOffsetFromEntityInWorldCoords(vehicle, grapplerOffset.x, grapplerOffset.y + 0.4, grapplerOffset.z)
                    local closestBone
                    local closestBoneDistance = 5.0
                    local WHEEL_BONES = {"wheel_lf", "wheel_rf", "wheel_lm", "wheel_rm", "wheel_lr", "wheel_rr", "rudder_l", "rudder_r", "rudder", "rudder2", "rudder_2"}
                    for i, bone in ipairs(WHEEL_BONES) do
                        local coords = GetWorldPositionOfEntityBone(closestTarget, GetEntityBoneIndexByName(closestTarget, bone))
                        if i > 5 then
                            coords = coords + vector3(0.0, 0.0, 1.0)
                        end
                        local distance = #(grapplerPosition - coords)
                        if distance < closestBoneDistance then
                            closestBone = bone
                            closestBoneDistance = distance
                        end
                    end
                    if closestBoneDistance < 1.0 then
                        TriggerServerEvent("pickle_policejob:grappler:attach", VehToNet(vehicle), VehToNet(closestTarget), {
                            boneId = closestBone,
                            grapplerOffset = grapplerOffset
                        })
                        Wait(1000)
                    end
                end
            end
            if IsControlJustPressed(1, 51) then
                TriggerServerEvent("pickle_policejob:grappler:toggleDeploy", VehToNet(vehicle))
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    -- if Config.UseTarget then return end
    while true do
        local wait = 1500
        if not DoesEntityExist(GetVehiclePedIsIn(PlayerPedId(), false)) then
            local closestVehicle = nil
            local closestDistance = 100.0
            for vehicleNetId, grapplerData in pairs(GrapplerVehicles) do
                local shouldRender = false
                if NetworkDoesNetworkIdExist(vehicleNetId) then
                    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
                    if DoesEntityExist(vehicle) then
                        local grapplerCoords = GetOffsetFromEntityInWorldCoords(vehicle, grapplerData.grapplerOffset.x, grapplerData.grapplerOffset.y, grapplerData.grapplerOffset.z)
                        local distance = #(grapplerCoords - GetEntityCoords(PlayerPedId()))
                        if distance < Config.Grappler.renderDistance then 
                            shouldRender = true
                        end
                        if distance < closestDistance then
                            closestVehicle = vehicle
                            closestDistance = distance
                        end
                    end
                end
                if shouldRender and not LocalGrapplerVehicles[vehicleNetId] then
                    RenderVehicleGrappler(vehicleNetId)
                elseif not shouldRender and LocalGrapplerVehicles[vehicleNetId] then
                    UnrenderVehicleGrappler(vehicleNetId)
                end
            end
            if closestDistance < 2.0 then
                wait = 0
                ShowInteractText(_L("interact_grappler"))
                if IsControlJustPressed(1, 51) then
                    TriggerServerEvent("pickle_policejob:grappler:remove", VehToNet(closestVehicle))
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent("pickle_policejob:grappler:setDeployed", function(vehicleNetId, deployed)
    if not GrapplerVehicles[vehicleNetId] then return end
    GrapplerVehicles[vehicleNetId].deployed = deployed
    RenderVehicleGrappler(vehicleNetId)
end)

RegisterNetEvent("pickle_policejob:grappler:attachToVehicle", function(vehicleNetId, grapplerData)
    GrapplerVehicles[vehicleNetId] = grapplerData
    RenderVehicleGrappler(vehicleNetId)
    if Config.UseTarget then
        AddTargetNetworkId(vehicleNetId, TARGET_OPTIONS)
    end
end)

RegisterNetEvent("pickle_policejob:grappler:attach", function(vehicleNetId, targetVehicleNetId, grapplerData)
    GrapplerVehicles[vehicleNetId] = grapplerData
    RenderVehicleGrappler(vehicleNetId)
end)

RegisterNetEvent("pickle_policejob:grappler:remove", function(vehicleNetId)
    if not GrapplerVehicles[vehicleNetId] then return end
    RemoveVehicleGrappler(vehicleNetId)
    if Config.UseTarget then
        RemoveTargetNetworkId(vehicleNetId, TARGET_OPTIONS)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for vehicleNetId, grapplerData in pairs(GrapplerVehicles) do
            RemoveVehicleGrappler(vehicleNetId)
        end
    end
end)