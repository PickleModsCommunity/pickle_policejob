local BulletTimeout = {}
local Evidence = {}

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