local BulletTimeout = {}
local Evidence = {}
local VehiclePrints = {}
local CachedDNA = {}

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

function GetPlayerEvidence(source)
    local inventory = Inventory.GetInventory(source)
    local items = {}
    for _, item in pairs(inventory) do
        if item.name == "evidence_report" then
            local evidence = item.metadata.evidence
            for i=1, #evidence do
                if evidence[i].coords then
                    evidence[i].coords = {
                        x = evidence[i].coords.x,
                        y = evidence[i].coords.y,
                        z = evidence[i].coords.z,
                    }
                end
                if evidence[i].direction then
                    evidence[i].direction = {
                        x = evidence[i].direction.x,
                        y = evidence[i].direction.y,
                        z = evidence[i].direction.z,
                    }
                end
            end
            table.insert(items, {
                name = item.name,
                evidence = evidence,
                slot = item.slot,
            })
        end
    end
    return items
end

function GetPlayerDNA(source)
    if CachedDNA[source] then return CachedDNA[source] end
    local result = MySQL.query.await("SELECT * FROM pickle_police_dna WHERE identifier = ?", {
        GetIdentifier(source),
    })
    if not result[1] then 
        local dna
        repeat
            dna = ""
            for i=1, 6 do
                local random = math.random(1, 2)
                dna = dna .. string.char(random == 1 and math.random(65, 90) or math.random(48, 57))
            end
        until not MySQL.query.await("SELECT * FROM pickle_police_dna WHERE dna = ?", {
            dna,
        })[1]
        MySQL.query("INSERT INTO pickle_police_dna (identifier, dna) VALUES (?, ?)", {
            GetIdentifier(source),
            dna,
        })
        result = {{dna = dna}}
    end
    CachedDNA[source] = result[1].dna
    return result[1].dna
end

lib.callback.register("pickle_policejob:evidence:getFiles", function(source, search)
    local result
    if search == "" then
        result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE departmentId = ? ORDER BY datetime DESC LIMIT ?", {
            GetPlayerDepartment(source),
            Config.Evidence.maxFilesQuery,
        })
    else
        result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE departmentId = ? AND (name LIKE ? OR evidence LIKE ?) LIMIT ?", {
            GetPlayerDepartment(source),
            "%" .. search .. "%",
            "%" .. search .. "%",
            Config.Evidence.maxFilesQuery,
        })
    end
    return result
end)

lib.callback.register("pickle_policejob:evidence:getEvidenceItems", function(source)
    return GetPlayerEvidence(source)
end)

lib.callback.register("pickle_policejob:evidence:createFile", function(source, data)
    local file = {
        name = data.name,
        authorIdentifier = GetIdentifier(source),
        datetime = os.time(),
        document = data.document,
        evidence = data.evidence,
    }
    local result = MySQL.query.await("INSERT INTO pickle_police_files (departmentId, name, authorIdentifier, datetime, document, evidence) VALUES (?, ?, ?, ?, ?, ?)", {
        GetPlayerDepartment(source),
        file.name,
        file.authorIdentifier,
        file.datetime,
        json.encode(file.document),
        json.encode(file.evidence),
    })
    file.id = result.insertId
    return file
end)

lib.callback.register("pickle_policejob:evidence:deleteEvidenceItem", function(source, name, slot)
    local p = promise.new()
    Inventory.RemoveItem(source, name, 1, slot)
    SetTimeout(100, function()
        p:resolve(true)
    end)
    Citizen.Await(p)
    return GetPlayerEvidence(source)
end)

RegisterNetEvent("pickle_policejob:evidence:addShellCasing", function(data)
    local source = source
    if BulletTimeout[source] and BulletTimeout[source] > os.time() then return print("^1ERROR: BULLET TIMEOUT:^0", source) end
    BulletTimeout[source] = os.time() + Config.Evidence.queueInterval
    AddEvidence(data.origin, "shell_casing", {
        identifier = GetPlayerDNA(source),
        coords = data.origin,
        time = os.time(),
        direction = data.direction,
        heading = data.heading,
        weaponGroup = data.weaponGroup,
        type = "shell_casing",
        amount = data.amount,
    })
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
        identifier = GetPlayerDNA(source),
        heading = 0.0,
    })
end)

RegisterNetEvent("pickle_policejob:evidence:addVehiclePrint", function(vehicleNetId, seatIndex)
    local source = source
    if not VehiclePrints[vehicleNetId] then
        VehiclePrints[vehicleNetId] = {}
    end
    VehiclePrints[vehicleNetId][seatIndex] = {
        identifier = GetPlayerDNA(source),
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

RegisterNetEvent("pickle_policejob:evidence:updateFileDocument", function(id, content)
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ?", {
        id,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", id) end
    local document = json.decode(result[1].document)
    document.content = content
    MySQL.query("UPDATE pickle_police_files SET document = ? WHERE id = ?", {
        json.encode(document),
        id,
    })
end)

RegisterNetEvent("pickle_policejob:evidence:importEvidence", function(id, importedEvidence)
    local source = source
    local departmentId = GetPlayerDepartment(source)
    if not departmentId then return print("^1ERROR: NOT AUTHORIZED:^0", id) end
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ? AND departmentId = ?", {
        id,
        departmentId,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", id) end
    local evidence = json.decode(result[1].evidence)
    for i=1, #importedEvidence do
        table.insert(evidence, importedEvidence[i])
    end
    MySQL.query("UPDATE pickle_police_files SET evidence = ? WHERE id = ?", {
        json.encode(evidence),
        id,
    })
end)

RegisterNetEvent("pickle_policejob:evidence:deleteEvidence", function(id, index)
    local source = source
    local departmentId = GetPlayerDepartment(source)
    if not departmentId then return print("^1ERROR: NOT AUTHORIZED:^0", id) end
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ? AND departmentId = ?", {
        id,
        departmentId,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", id) end
    local evidence = json.decode(result[1].evidence)
    table.remove(evidence, index)
    MySQL.query("UPDATE pickle_police_files SET evidence = ? WHERE id = ?", {
        json.encode(evidence),
        id,
    })
end)

RegisterNetEvent("pickle_policejob:evidence:printFile", function(id)
    local source = source
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ?", {
        id,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", id) end
    local file = {
        name = result[1].name,
        authorIdentifier = result[1].authorIdentifier,
        datetime = result[1].datetime,
        document = json.decode(result[1].document),
        evidence = json.decode(result[1].evidence),
    }
    Inventory.AddItem(source, "police_report", 1, {
        fileId = id,
    })
end)

RegisterUsableItem("police_report", function(source, item, data)
    local metadata = Config.FrameworkSettings.usableItemMetadata(item, data)
    if not metadata or not metadata.fileId then return end
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ?", {
        metadata.fileId,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", metadata.fileId) end
    local file = {
        id = result[1].id,
        name = result[1].name,
        authorIdentifier = result[1].authorIdentifier,
        datetime = result[1].datetime,
        document = json.decode(result[1].document),
        evidence = json.decode(result[1].evidence),
    }
    TriggerClientEvent("pickle_policejob:evidence:viewFile", source, file)
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
        identifier = GetPlayerDNA(sender),
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

MySQL.ready(function()
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_files (id INT AUTO_INCREMENT PRIMARY KEY, departmentId INT, name VARCHAR(255), authorIdentifier VARCHAR(255), datetime INT, document LONGTEXT, evidence LONGTEXT)")
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_dna (identifier VARCHAR(255) PRIMARY KEY, dna VARCHAR(255))")
end)