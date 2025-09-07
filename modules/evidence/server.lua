if not Config.Evidence.enabled then return end

local BulletTimeout = {}
local Evidence = {}
local VehiclePrints = {}
local CachedDNA = {}
local GSRTracking = {}
local AwaitedDNA = {}

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

exports("AddEvidence", AddEvidence)

function GetAnyValue(table, keys)
    if not table or type(table) ~= "table" then return end
    for _, key in pairs(keys) do
        if table[key] then
            return table[key]
        end
    end
end

function CanCreateEvidence(coords)
    for _, zone in pairs(Config.Evidence.evidenceExclusionZones or {}) do
        if #(coords - zone.coords) < zone.radius then
            return false
        end
    end
    return true
end

function GetPlayerEvidence(source, isCreatingFile)
    local inventory = Inventory.GetInventory(source)
    local items = {}
    local coords = GetEntityCoords(GetPlayerPed(source))
    local heading = GetEntityHeading(GetPlayerPed(source))
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
        elseif not isCreatingFile then
            item.evidence = {
                {
                    type = "item",
                    label = item.label,
                    image = item.image or (Config.ImageDirectory .. "/" .. item.name .. "." .. (Config.ImageExtension or "png")),
                    time = os.time(),
                    coords = coords,
                    heading = heading,
                    serial = GetAnyValue(item.metadata, {"serial", "serialnumber", "serial_number"}),
                    item = {
                        slot = item.slot,
                    },
                }
            }
            table.insert(items, {
                name = item.name,
                evidence = item.evidence,
                slot = item.slot,
            })
        end
    end
    return items
end

function GetPlayerDNA(source)
    if CachedDNA[source] then return CachedDNA[source] end
    if AwaitedDNA[source] then return Citizen.Await(AwaitedDNA[source]) end
    AwaitedDNA[source] = promise.new()
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
    if AwaitedDNA[source] then
        AwaitedDNA[source]:resolve(result[1].dna)
        AwaitedDNA[source] = nil
    end
    return result[1].dna
end

function GetPlayerBAC(source)
    if GetResourceState("envi_addictions") == "started" then
        return (exports['envi-addictions']:Breathalyze(targetServerId) / 3) / 10
    end
    if ExternalStatus and ExternalStatus.Alcohol[source] then return ExternalStatus.Alcohol[source] end
    if GetPlayerStatus(source) then
        return GetPlayerStatus(source).Alcohol
    end
    return 0.0
end

function GetPlayerBloodTest(source)
    if GetResourceState("envi_addictions") == "started" then
        return nil
    end
    return {
        weed = 3
    }
end

function GetPlayerGSR(source)
    if GSRTracking[source] and (GSRTracking[source] + Config.Evidence.gsrDuration) > os.time() then
        return true
    end
    return false
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

lib.callback.register("pickle_policejob:evidence:getEvidenceItems", function(source, isCreatingFile)
    return GetPlayerEvidence(source, isCreatingFile)
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
    ShowNotification(source, _L("file_created"))
    return file
end)

lib.callback.register("pickle_policejob:evidence:deleteEvidenceItem", function(source, name, slot)
    local p = promise.new()
    Inventory.RemoveItem(source, name, 1, slot)
    SetTimeout(100, function()
        p:resolve(true)
    end)
    Citizen.Await(p)
    ShowNotification(source, _L("evidence_item_deleted"))
    return GetPlayerEvidence(source)
end)

lib.callback.register("pickle_policejob:evidence:getBAC", function(source, target)
    return GetPlayerBAC(target)
end)

RegisterNetEvent("pickle_policejob:evidence:addBAC", function(target, bac)
    local source = source
    Inventory.AddItem(source, "evidence_report", 1, {
        evidenceType = "bac",
        evidence = {
            {
                type = "bac",
                label = _L("breathalyzer_results"),
                identifier = GetPlayerDNA(target),
                image = "nui://pickle_policejob/nui/images/bac.png",
                time = os.time(),
                coords = GetEntityCoords(GetPlayerPed(target)),
                heading = GetEntityHeading(GetPlayerPed(target)),
                bac = bac,
            }
        },
    })
    ShowNotification(source, _L("bac_added"))
end)

RegisterNetEvent("pickle_policejob:evidence:addBloodTest", function(target, results)
    local source = source
    Inventory.AddItem(source, "evidence_report", 1, {
        evidenceType = "blood_test",
        evidence = {
            {
                type = "blood_test",
                label = _L("blood_test_results"),
                identifier = GetPlayerDNA(target),
                image = "nui://pickle_policejob/nui/images/blood_test.png",
                time = os.time(),
                coords = GetEntityCoords(GetPlayerPed(target)),
                heading = GetEntityHeading(GetPlayerPed(target)),
                results = results,
            }
        },
    })
end)

RegisterNetEvent("pickle_policejob:evidence:addShellCasing", function(data)
    local source = source
    if BulletTimeout[source] and BulletTimeout[source] > os.time() then return print("^1ERROR: BULLET TIMEOUT:^0", source) end
    if not CanCreateEvidence(data.origin) then return end
    BulletTimeout[source] = os.time() + Config.Evidence.queueInterval
    GSRTracking[source] = os.time()
    TriggerClientEvent("pickle_policejob:evidence:setHasGSR", source, true)
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
    Evidence[id] = nil
    TriggerClientEvent("pickle_policejob:evidence:removeEvidence", -1, id)
end)

RegisterNetEvent("pickle_policejob:evidence:addBlood", function()
    local source = source
    if not CanCreateEvidence(GetEntityCoords(GetPlayerPed(source)) - vector3(0.0, 0.0, 1.0)) then return end
    AddEvidence(GetEntityCoords(GetPlayerPed(source)) - vector3(0.0, 0.0, 1.0), "blood", {
        identifier = GetPlayerDNA(source),
        time = os.time(),
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
    ShowNotification(source, _L("evidence_saved"))
end)

RegisterNetEvent("pickle_policejob:evidence:updateFileDocument", function(id, content)
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ?", {
        id,
    })
    if not result[1] then return print("^1ERROR: FILE NOT FOUND:^0", id) end
    local file = result[1]
    file.document = json.decode(file.document)
    file.document.content = content
    MySQL.query("UPDATE pickle_police_files SET document = ? WHERE id = ?", {
        json.encode(file.document),
        id,
    })
    SendComputerEvent("pickle_policejob:evidence:updateFile", {
        id = id,
        file = file,
    })
    ShowNotification(source, _L("file_document_updated"))
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
    local file = result[1]
    local evidence = json.decode(file.evidence)
    for i=1, #importedEvidence do
        local canAdd = true
        if importedEvidence[i].type == "item" and importedEvidence[i].item.slot then
            local slot = importedEvidence[i].item.slot
            local inventory = Inventory.GetInventory(source) or {}
            local found = false
            for _, item in pairs(inventory) do
                if item.slot == slot then
                    importedEvidence[i].item = item
                    found = true
                    break
                end
            end
            if found then
                Inventory.RemoveItem(source, importedEvidence[i].item.name, importedEvidence[i].item.count, slot)
            else
                canAdd = false
            end
        end
        if canAdd then
            table.insert(evidence, importedEvidence[i])
        end
    end
    file.evidence = evidence
    SendComputerEvent("pickle_policejob:evidence:updateFile", {
        id = id,
        file = file,
    })
    MySQL.query("UPDATE pickle_police_files SET evidence = ? WHERE id = ?", {
        json.encode(file.evidence),
        id,
    })
    ShowNotification(source, _L("evidence_imported"))
end)

RegisterNetEvent("pickle_policejob:evidence:deleteEvidence", function(id, index)
    local source = source
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId then return ShowNotification(source, _L("not_on_duty")) end
    local result = MySQL.query.await("SELECT * FROM pickle_police_files WHERE id = ? AND departmentId = ?", {
        id,
        departmentId,
    })
    if not result[1] then return ShowNotification(source, _L("file_not_found")) end
    local file = result[1]
    file.evidence = json.decode(file.evidence)
    local rank, rankIndex = GetDepartmentRank(departmentId, member)
    if result[1].authorIdentifier ~= GetIdentifier(source) and rankIndex > 1 then return ShowNotification(source, _L("no_department_permission")) end
    local evidence = file.evidence
    if evidence[index].type == "item" then
        Inventory.AddItem(source, evidence[index].item.name, evidence[index].item.count, evidence[index].item.metadata)
    end
    table.remove(evidence, index)
    file.evidence = evidence
    MySQL.query("UPDATE pickle_police_files SET evidence = ? WHERE id = ?", {
        json.encode(file.evidence),
        id,
    })
    SendComputerEvent("pickle_policejob:evidence:updateFile", {
        id = id,
        file = file,
    })
    ShowNotification(source, _L("evidence_deleted"))
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
    ShowNotification(source, _L("file_printed"))
end)

RegisterNetEvent("pickle_policejob:evidence:addFingerprint", function(targetId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    Inventory.AddItem(source, "evidence_report", 1, {
        evidenceType = "fingerprint",
        evidence = {
            {
                type = "fingerprint",
                label = _L("fingerprint"),
                identifier = GetPlayerDNA(targetId),
                image = "nui://pickle_policejob/nui/images/fingerprint.png",
                time = os.time(),
                coords = GetEntityCoords(GetPlayerPed(targetId)),
                heading = GetEntityHeading(GetPlayerPed(targetId)),
                name = GetPlayerCharacterName(targetId),
            }
        },
    })
    ShowNotification(source, _L("fingerprint_added"))
end)

RegisterNetEvent("pickle_policejob:evidence:addGSR", function(targetId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    Inventory.AddItem(source, "evidence_report", 1, {
        evidenceType = "gsr",
        evidence = {
            {
                type = "gsr",
                label = _L("gsr"),
                result = GetPlayerGSR(targetId) and _L("positive") or _L("negative"),
                identifier = GetPlayerDNA(targetId),
                image = "nui://pickle_policejob/nui/images/fingerprint.png",
                time = os.time(),
                coords = GetEntityCoords(GetPlayerPed(targetId)),
                heading = GetEntityHeading(GetPlayerPed(targetId)),
                name = GetPlayerCharacterName(targetId),
            }
        },
    })
    ShowNotification(source, _L("gsr_added"))
end)

RegisterNetEvent("pickle_policejob:evidence:washOffGSR", function()
    local source = source
    GSRTracking[source] = nil
    ShowNotification(source, _L("gsr_washed_off"))
    TriggerClientEvent("pickle_policejob:evidence:setHasGSR", source, false)
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
    ShowNotification(source, _L("evidence_report_used"))
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

lib.callback.register("pickle_policejob:evidence:canPickupEvidence", function(source, id)
    local source = source
    local evidence = Evidence[id]
    if not evidence then return ShowNotification(source, _L("evidence_not_found")) end
    if evidence.time then
        local timeLeft = (evidence.time + Config.Evidence.pickupCooldown) - os.time()
        if timeLeft > 0 then return ShowNotification(source, _L("evidence_pickup_cooldown", timeLeft)) end
    end
    return true
end)

AddEventHandler('explosionEvent', function(sender, ev)
    local coords = vector3(ev.posX, ev.posY, ev.posZ)
    if not CanCreateEvidence(coords) then return end
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

if Config.Evidence.evidenceRemove > 0 then
    lib.cron.new("*/1 * * * *", function()
        local removePack = {}
        for id, evidence in pairs(Evidence) do
            if evidence.time and (evidence.time + Config.Evidence.evidenceRemove) < os.time() then
                Evidence[id] = nil
                table.insert(removePack, id)
            end
        end
        TriggerClientEvent("pickle_policejob:evidence:removeEvidence", -1, removePack)
    end)
end

MySQL.ready(function()
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_files (id INT AUTO_INCREMENT PRIMARY KEY, departmentId INT, name VARCHAR(255), authorIdentifier VARCHAR(255), datetime INT, document LONGTEXT, evidence LONGTEXT)")
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_dna (identifier VARCHAR(255) PRIMARY KEY, dna VARCHAR(255))")
end)