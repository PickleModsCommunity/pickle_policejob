local GrapplerVehicles = {}

RegisterNetEvent("pickle_policejob:grappler:attach", function(vehicleNetId, targetNetId, data)
    if not GrapplerVehicles[vehicleNetId] or GrapplerVehicles[vehicleNetId].targetNetId then return end
    local source = source
    if not IsPlayerOnDuty(source) then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    local targetVehicle = NetworkGetEntityFromNetworkId(targetNetId)
    if not DoesEntityExist(targetVehicle) then return end
    GrapplerVehicles[vehicleNetId].targetNetId = targetNetId
    GrapplerVehicles[vehicleNetId].boneId = data.boneId
    TriggerClientEvent("pickle_policejob:grappler:attach", -1, NetworkGetNetworkIdFromEntity(vehicle), NetworkGetNetworkIdFromEntity(targetVehicle), GrapplerVehicles[vehicleNetId])
end)

RegisterNetEvent("pickle_policejob:grappler:toggleDeploy", function(vehicleNetId)
    if not IsPlayerOnDuty(source) then return end
    if not GrapplerVehicles[vehicleNetId] or GrapplerVehicles[vehicleNetId].targetNetId then return end
    GrapplerVehicles[vehicleNetId].deployed = not GrapplerVehicles[vehicleNetId].deployed
    TriggerClientEvent("pickle_policejob:grappler:setDeployed", -1, vehicleNetId, GrapplerVehicles[vehicleNetId].deployed)
end)

RegisterNetEvent("pickle_policejob:grappler:attachToVehicle", function(vehicleNetId, data)
    local source = source
    if not IsPlayerOnDuty(source) then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    GrapplerVehicles[vehicleNetId] = {
        deployed = false,
        grapplerOffset = data.grapplerOffset, --or vector3(0.0, 2.55, 0.0),
        targetNetId = nil,
        boneId = nil,
    }
    TriggerClientEvent("pickle_policejob:grappler:attachToVehicle", -1, vehicleNetId, GrapplerVehicles[vehicleNetId])
end)

RegisterNetEvent("pickle_policejob:grappler:remove", function(vehicleNetId)
    if not GrapplerVehicles[vehicleNetId] then return end
    GrapplerVehicles[vehicleNetId] = nil
    TriggerClientEvent("pickle_policejob:grappler:remove", -1, vehicleNetId)
end)

AddEventHandler("entityRemoved", function(entity)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(entity)
    if GrapplerVehicles[vehicleNetId] then 
        GrapplerVehicles[vehicleNetId] = nil
        TriggerClientEvent("pickle_policejob:grappler:remove", -1, vehicleNetId)
    else
        for id, grapplerData in pairs(GrapplerVehicles) do
            if grapplerData.targetNetId == vehicleNetId then
                GrapplerVehicles[id] = nil
                TriggerClientEvent("pickle_policejob:grappler:remove", -1, id)
            end
        end
    end

end)