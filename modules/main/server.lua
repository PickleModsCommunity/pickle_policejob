function InitializeDepartment(id, data, dontSync)
    local department = {
        id = id,
        label = data.label,
        members = data.members,
        entities = data.entities,
    }
    Departments[id] = department
    if dontSync then return end
    TriggerClientEvent("pickle_policejob:initializeDepartment", -1, id, department)
end

function GetDepartment(id)
    return Departments[id]
end

function GetPlayerDepartment(source)
    local identifier = GetIdentifier(source)
    for k, v in pairs(Departments) do
        for i=1, #v.members do
            if v.members[i].identifier == identifier then
                return k, v.members[i]
            end
        end
    end
    return nil
end

function GetDepartmentEntity(id, entityId)
    local department = GetDepartment(id)
    for i=1, #department.entities do
        if department.entities[i].id == entityId then
            return department.entities[i], i
        end
    end
    return nil
end

function IsPlayerOnDuty(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return false end
    return memberData.onDuty
end

function EnsureDepartmentData(key, data)
    if not data then return end
    if key == "label" then
        return data or "ERR_UNKNOWN"
    elseif key == "location" then
        if not data or not data.coords or data.heading == nil then
            return {
                coords = vector3(0.0, 0.0, 0.0),
                heading = 0.0,
            }
        else
            return data
        end
    else
        return data or {}
    end
end

function DoesPlayerHaveEntityPermission(source, id, entityId)
    local departmentId, memberData = GetPlayerDepartment(source)
    local entity, entityIndex = GetDepartmentEntity(id, entityId)
    if not entity then return false end
    if not entity.permissions or #entity.permissions == 0 then return true end
    if not memberData or not memberData.permissions or #memberData.permissions == 0 then return false end
    for i=1, #entity.permissions do
        for j=1, #memberData.permissions do
            if entity.permissions[i] == memberData.permissions[j] then
                return true
            end
        end
    end
    return false
end

RegisterCallback("pickle_policejob:openFrontdesk", function(source, cb, id, entityId)
    local department = GetDepartment(id)
    local departmentId, memberData = GetPlayerDepartment(source)
    local time = os.time()
    if not DoesPlayerHaveEntityPermission(source, id, entityId) then 
        cb(nil) 
        return ShowNotification(source, _L("no_department_permission")) 
    end
    cb({
        departmentId = departmentId,
        memberData = memberData,
        time = time,
    })
end)

RegisterNetEvent("pickle_policejob:toggleDuty", function(id, entityId)
    
end)

RegisterNetEvent("pickle_policejob:initializePlayer", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("pickle_policejob:initializeDepartment", -1, Departments)
end)

MySQL.ready(function()
    -- local department = Config.Departments[11]
    -- MySQL.Async.execute("INSERT IGNORE INTO pickle_police_departments (id, label, location, members, entities, permissions, ranks, outfits) VALUES (@id, @label, @location, @members, @entities, @permissions, @ranks, @outfits)", {
    --     id = 11,
    --     label = department.label,
    --     location = json.encode(department.location),
    --     members = json.encode(department.members),
    --     entities = json.encode(department.entities),
    --     permissions = json.encode(department.permissions),
    --     ranks = json.encode(department.ranks),
    --     outfits = json.encode(department.outfits),
    -- })
    MySQL.Async.fetchAll("SELECT * FROM pickle_police_departments", {}, function(result)
        for k, v in pairs(result) do
            InitializeDepartment(v.id, {
                label = EnsureDepartmentData("label", v.label),
                location = EnsureDepartmentData("location", json.decode(v.location)),
                members = EnsureDepartmentData("members", json.decode(v.members)),
                entities = EnsureDepartmentData("entities", json.decode(v.entities)),
                permissions = EnsureDepartmentData("permissions", json.decode(v.permissions)),
                ranks = EnsureDepartmentData("ranks", json.decode(v.ranks)),
                outfits = EnsureDepartmentData("outfits", json.decode(v.outfits)),
            }, true)
        end
    end)
end)