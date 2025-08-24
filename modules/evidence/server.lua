local BulletTimeout = {}
local Evidence = {}
local VehiclePrints = {}

function EnsureEvidence(coords, evidenceType, data)
    data.label = _L(evidenceType)
    data.type = evidenceType
    data.coords = coords
    return data
end

function AddEvidence(coords, evidenceType, data)
    local data = EnsureEvidence(coords, evidenceType, data)
    if not data then return print("^1ERROR: CANT ADD EVIDENCE:^0", evidenceType, coords, data) end
    for id, evidence in pairs(Evidence) do
        if evidence.type == evidenceType and #(evidence.coords - coords) < Config.Evidence.evidenceGroupDistance then
            if evidence.type == "shell_casing" then
                evidence.amount = evidence.amount + 1
                TriggerClientEvent("pickle_policejob:evidence:updateEvidence", -1, id, evidence)
                return
            elseif evidence.type == "blood" and evidence.identifier == data.identifier then
                return
            end
        end
    end
    local id
    repeat
        id = math.random(1, 1000000)
    until not Evidence[id]
    Evidence[id] = data
    TriggerClientEvent("pickle_policejob:evidence:addEvidence", -1, id, data)
end

RegisterNetEvent("pickle_policejob:evidence:addShellCasing", function(data)
    local source = source
    if BulletTimeout[source] and BulletTimeout[source] > os.time() then return print("^1ERROR: BULLET TIMEOUT:^0", source) end
    BulletTimeout[source] = os.time() + Config.Evidence.queueInterval
    AddEvidence(data.origin, "shell_casing", data)
end)

RegisterNetEvent("pickle_policejob:evidence:pickupEvidence", function(id)
    local source = source
    local evidence = Evidence[id]
    if not evidence then return print("^1ERROR: EVIDENCE NOT FOUND:^0", id) end
    TriggerClientEvent("pickle_policejob:evidence:removeEvidence", -1, id)
end)

RegisterNetEvent("pickle_policejob:evidence:addBlood", function()
    local source = source
    AddEvidence(GetEntityCoords(GetPlayerPed(source)) - vector3(0.0, 0.0, 1.0), "blood", {
        identifier = GetIdentifier(source),
        heading = 0.0,
    })
end)

RegisterNetEvent("pickle_policejob:evidence:addVehiclePrint", function(vehicleNetId, seatIndex)
    local source = source
    if not VehiclePrints[vehicleNetId] then
        VehiclePrints[vehicleNetId] = {}
    end
    VehiclePrints[vehicleNetId][seatIndex] = {
        identifier = GetIdentifier(source),
        time = os.time(),
    }
end)

RegisterNetEvent("pickle_policejob:evidence:saveEvidence", function(evidenceType, evidence)
    local source = source
    Inventory.AddItem(source, "evidence_report", 1, {
        evidenceType = evidenceType,
        evidence = evidence,
    })
end)

RegisterUsableItem("police_report", function(source, item, data)
    local metadata = Config.FrameworkSettings.usableItemMetadata(item, data)
    if not metadata then return end
end)

RegisterUsableItem("evidence_report", function(source, item, data)
    local metadata = Config.FrameworkSettings.usableItemMetadata(item, data)
    if not metadata then return end
    print(json.encode(metadata, {indent = true}))
end)

lib.callback.register("pickle_policejob:evidence:getVehicleInfo", function(source, vehicleNetId)
    local entity = NetworkGetEntityFromNetworkId(vehicleNetId)
    return {
        coords = GetEntityCoords(entity),
        heading = GetEntityHeading(entity),
        plate = GetVehicleNumberPlateText(entity) or "UNKNOWN",
        seats = VehiclePrints[vehicleNetId] or {},
    }
end)

AddEventHandler('explosionEvent', function(sender, ev)
    local coords = vector3(ev.posX, ev.posY, ev.posZ)
    AddEvidence(coords, "fire", {
        explosionType = ev.explosionType,
        identifier = GetIdentifier(sender),
        heading = 0.0,
    })
end)

AddEventHandler("entityRemoved", function(entity)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(entity)
    if VehiclePrints[vehicleNetId] then 
        VehiclePrints[vehicleNetId] = nil
    end
end)

CreateThread(function()
    Wait(2000)
    AddEvidence(vector3(2135.8401, 4780.9956, 39.9703), "shell_casing", {
        direction = vector3(2123.0669, 4786.7773, 40.9797),
        origin = vector3(2135.8401, 4780.9956, 39.9703),
        heading = 28.3079,
        weaponGroup = "GROUP_SHOTGUN",
        type = "shell_casing",
        amount = 3,
    })
end)