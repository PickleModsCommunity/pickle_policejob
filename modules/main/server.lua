function InitializeDepartment(id, data, dontSync)
    local department = {
        id = id,
        label = data.label,
        location = data.location,
        locations = EnsureDepartmentData("locations", data.locations),
        members = data.members,
        ranks = data.ranks,
        outfits = data.outfits,
        permissions = data.permissions,
        misc = data.misc,
    }
    Departments[id] = department
    if dontSync then return end
    TriggerClientEvent("pickle_policejob:initializeDepartment", -1, id, department)
end

function UpdateDepartmentSQL(id, columnId)
    local department = GetDepartment(id)
    if not department then return end
    if columnId == "label" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET label = @label WHERE id = @id", {
            label = department.label,
            id = id,
        })
    elseif columnId == "location" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET location = @location WHERE id = @id", {
            location = json.encode(department.location),
            id = id,
        })
    elseif columnId == "members" then
        local members = {}
        for i=1, #department.members do
            table.insert(members, RemoveFields(department.members[i], {"onDuty"}))
        end
        MySQL.Async.execute("UPDATE pickle_police_departments SET members = @members WHERE id = @id", {
            members = json.encode(members),
            id = id,
        })
    elseif columnId == "locations" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET locations = @locations WHERE id = @id", {
            locations = json.encode(department.locations),
            id = id,
        })
    elseif columnId == "permissions" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET permissions = @permissions WHERE id = @id", {
            permissions = json.encode(department.permissions),
            id = id,
        })
    elseif columnId == "ranks" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET ranks = @ranks WHERE id = @id", {
            ranks = json.encode(department.ranks),
            id = id,
        })
    elseif columnId == "outfits" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET outfits = @outfits WHERE id = @id", {
            outfits = json.encode(department.outfits),
            id = id,
        })
    end
end

function DeleteDepartment(id)
    Departments[id] = nil
    TriggerClientEvent("pickle_policejob:deleteDepartment", -1, id)
end

function GetDepartment(id)
    return Departments[id]
end

function GetDepartmentPermission(id, permission)
    local department = GetDepartment(id)
    if not department then return nil end
    return department.permissions[permission]
end

function GetDepartmentMember(id, source)
    local department = GetDepartment(id)
    local identifier = GetIdentifier(source)
    if not department then return nil end
    for i=1, #department.members do
        if department.members[i].identifier == identifier then
            return department.members[i], i
        end
    end
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

function GetIdentifierDepartment(identifier)
    for k, v in pairs(Departments) do
        for i=1, #v.members do
            if v.members[i].identifier == identifier then
                return k, v.members[i]
            end
        end
    end
end

function GetDepartmentEntity(id, entityId)
    local department = GetDepartment(id)
    for i=1, #department.locations do
        if department.locations[i].id == entityId then
            return department.locations[i], i
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
        if not data or not data.coords or data.rotation == nil then
            return {
                coords = vector3(0.0, 0.0, 0.0),
                rotation = vector3(0.0, 0.0, 0.0),
            }
        else
            return {
                coords = vector3(data.coords.x, data.coords.y, data.coords.z),
                rotation = vector3(data.rotation.x, data.rotation.y, data.rotation.z),
            }
        end
    elseif key == "locations" then
        if not data or type(data) ~= "table" then return {} end
        local locations = {}
        for i=1, #data do
            local positions = {}
            for k, v in pairs(data[i].positions) do
                positions[k] = EnsureDepartmentData("location", v)
            end
            locations[#locations+1] = {
                id = data[i].id,
                type = data[i].type,
                positions = positions,
                settings = data[i].settings or {},
            }
        end
        return locations
    else
        return data or {}
    end
end

function DoesPlayerHaveEntityPermission(source, id, entityId, onDutyRequired)
    local departmentId, memberData = GetPlayerDepartment(source)
    local entity, entityIndex = GetDepartmentEntity(id, entityId)
    if not entity then return false end
    if onDutyRequired and (not departmentId or not memberData.onDuty) then return false end
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

function ExecuteIntegration(source, integration, ...)
    if Config.Integrations and Config.Integrations[integration] and Config.Integrations[integration].server then
        Config.Integrations[integration].server(source, ...)
        if Config.Integrations[integration].client then
            TriggerClientEvent("pickle_policejob:integration", source, integration, ...)
        end
    end
end

function SetPlayerDuty(source, onDuty, report)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return ShowNotification(source, _L("no_department_permission")) end
    if onDuty and not memberData.onDuty then
        memberData.onDuty = os.time()
        ShowNotification(source, _L("duty_on"))
        ExecuteIntegration(source, "duty", departmentId, true)
    elseif not onDuty and memberData.onDuty then
        local duration = os.time() - memberData.onDuty
        memberData.onDutyTime = (memberData.onDutyTime or 0) + duration
        memberData.onDuty = nil
        memberData.recentDutyLogs = memberData.recentDutyLogs or {}
        table.insert(memberData.recentDutyLogs, 1, {
            report = string.len(report) > 0 and report or nil,
            finish = os.time(),
            finishTimestamp = GetFormattedDate(os.time()),
            startTimestamp = GetFormattedDate(os.time() - duration),
            duration = duration
        })
        if #memberData.recentDutyLogs > 10 then
            table.remove(memberData.recentDutyLogs)
        end
        ShowNotification(source, _L("duty_off"))
        UpdateDepartmentSQL(departmentId, "members")
        ExecuteIntegration(source, "duty", departmentId, false, report)
    end
end

function GetDepartmentRank(id, rankId)
    local department = GetDepartment(id)
    if not department then return nil end
    for i=1, #department.ranks do
        if department.ranks[i].rankId == rankId then
            return department.ranks[i], i
        end
    end
    return nil
end

function CanRankManageRank(departmentId, rankId, targetRankId)
    local rank, rankIndex = GetDepartmentRank(departmentId, rankId)
    local targetRank, targetRankIndex = GetDepartmentRank(departmentId, targetRankId)
    if not rank or not targetRank then return false end
    if rankIndex == 1 then return true end -- If this is the leader rank, they can manage all ranks
    for i=1, #targetRank.managingRankIds do
        if targetRank.managingRankIds[i] == rankId then return true end
    end
    return false
end

function CanRankManagePermission(departmentId, rankId, permission)
    local department = GetDepartment(departmentId)
    if not department then return false end
    local permissionData = GetDepartmentPermission(departmentId, permission)
    if not permissionData then return false end
    if department.ranks[1].rankId == rankId then return true end -- If this is the leader rank, they can manage all permissions
    for i=1, #permissionData.managingRankIds do
        if permissionData.managingRankIds[i] == rankId then return true end
    end
    return false
end

function IsPlayerDepartmentLeader(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return false end
    local department = GetDepartment(departmentId)
    if not department then return false end
    local rank, rankIndex = GetDepartmentRank(departmentId, memberData.rankId)
    if not rank then return false end
    return rankIndex == 1
end

function CanRankAccessEntry(departmentId, rankId, entryId, entryType)
    local department = GetDepartment(departmentId)
    if not department then return false end
    if department.ranks[1].rankId == rankId then
        return true
    end
    for i=#department.ranks, 1, -1 do
        local rank = department.ranks[i]
        for i=1, #rank[entryType] do 
            local target = rank[entryType][i]
            if target == entryId then
                return true
            end
        end
        if rank.id == rankId then
            break
        end
    end
    return false
end

function CanPermissionsAccessEntry(departmentId, permissions, entryId, entryType)
    local department = GetDepartment(departmentId)
    if not department then return false end
    for i=1, #permissions do
        local permission = department.permissions[permissions[i]]
        for j=1, #permission[entryType] do
            local target = permission[entryType][j]
            if target == entryId then
                return true
            end
        end
    end
    return false
end

RegisterCallback("pickle_policejob:openFrontdesk", function(source, cb, id)
    local department = GetDepartment(id)
    local departmentId, memberData = GetPlayerDepartment(source)
    local time = os.time()
    cb({
        departmentId = departmentId,
        memberData = memberData,
        time = time,
    })
end)

RegisterCallback("pickle_policejob:getPlayers", function(source, cb)
    local players = {}
    for k, v in pairs(GetPlayers()) do
        players[#players + 1] = {
            source = tonumber(v),
            identifier = GetIdentifier(v),
            name = GetPlayerCharacterName(v),
        }
    end
    cb(players)
end)

RegisterCallback("pickle_policejob:getPlayerInfo", function(source, cb)
    cb({
        identifier = GetIdentifier(source),
        name = GetPlayerCharacterName(source),
    })
end)

RegisterNetEvent("pickle_policejob:toggleDuty", function(id, entityId, report)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId or id ~= departmentId or not DoesPlayerHaveEntityPermission(source, id, entityId) then return ShowNotification(source, _L("no_department_permission")) end
    SetPlayerDuty(source, not memberData.onDuty, report)
end)

RegisterNetEvent("pickle_policejob:initializePlayer", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("pickle_policejob:setupInventory", source, Inventory.Items)
    TriggerClientEvent("pickle_policejob:initializeDepartment", source, Departments)
end)

AddEventHandler("onPlayerDropped", function(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return end
    if memberData.onDuty then
        SetPlayerDuty(source, false)
    end
end)

MySQL.ready(function()
    -- local department = Config.Departments[11]
    -- MySQL.Async.execute("INSERT IGNORE INTO pickle_police_departments (id, label, location, members, locations, permissions, ranks, outfits) VALUES (@id, @label, @location, @members, @locations, @permissions, @ranks, @outfits)", {
    --     id = 11,
    --     label = department.label,
    --     location = json.encode(department.location),
    --     members = json.encode(department.members),
    --     locations = json.encode(department.locations),
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
                locations = EnsureDepartmentData("locations", json.decode(v.locations)),
                permissions = EnsureDepartmentData("permissions", json.decode(v.permissions)),
                ranks = EnsureDepartmentData("ranks", json.decode(v.ranks)),
                outfits = EnsureDepartmentData("outfits", json.decode(v.outfits)),
                misc = EnsureDepartmentData("misc", json.decode(v.misc)),
            }, true)
        end
    end)
end)