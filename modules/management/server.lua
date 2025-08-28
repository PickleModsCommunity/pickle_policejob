local InManagement = {}

function GetManagementData()
    local departments = {}
    for id, department in pairs(Departments) do
        departments[#departments + 1] = {
            id = id,
            image = department.image,
            label = department.label,
            location = department.location,
            locations = department.locations,
            members = department.members,
            ranks = department.ranks,
            job = department.job,
        }
    end
    return {
        departments = departments,
    }
end

function GenerateUniqueLocationId(departmentId)
    local department = Departments[departmentId]
    if not department then return end
    local locationId = 1
    for i=1, #department.locations do
        if department.locations[i].id >= locationId then
            locationId = department.locations[i].id + 1
        end
    end
    return locationId
end

RegisterNetEvent("pickle_policejob:managementAction", function(action, data)
    local department
    local departmentId = data.departmentId
    if data.departmentId then
        department = Departments[data.departmentId]
        if not department then return end
    end
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    if action == "setDepartmentLeader" then
        local leaderRank = department.ranks[1]
        local demoteRank = department.ranks[2]
        local member = GetDepartmentMember(data.departmentId, data.source)
        local targetIdentifier = GetIdentifier(data.source)
        if member then
            member.rankId = leaderRank.rankId
        else
            table.insert(department.members, {
                identifier = targetIdentifier,
                name = GetPlayerCharacterName(data.source),
                rankId = leaderRank.rankId,
                recentDutyLogs = {},
                permissions = {},
            })
        end
        for i=1, #department.members do
            if department.members[i].identifier ~= targetIdentifier and department.members[i].rankId == leaderRank.rankId then
                if demoteRank then
                    department.members[i].rankId = demoteRank.rankId
                else
                    department.members[i] = nil
                end
            end
        end
        UpdateDepartmentSQL(data.departmentId, "members")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "updateMembers",
                departmentId = data.departmentId,
                members = department.members,
            })
        end
    elseif action == "updateLabel" then
        department.label = data.label
        UpdateDepartmentSQL(data.departmentId, "label")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "updateLabel",
                departmentId = data.departmentId,   
                label = data.label,
            })
        end
    elseif action == "updateImage" then
        department.image = data.image
        UpdateDepartmentSQL(data.departmentId, "image")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "updateImage",
                departmentId = data.departmentId,
                image = data.image,
            })
        end
    elseif action == "setDepartmentJob" then
        local jobCfg = Config.PoliceJobs[data.job]
        if not jobCfg then print("ERROR: Job not found: ", data.job) return end
        for i=1, #department.members do
            local rank, rankIndex = GetDepartmentRank(data.departmentId, department.members[i].rankId)
            if rankIndex == 1 then
                rank.jobLevel = jobCfg.maxLevel
            elseif rank.jobLevel > jobCfg.maxLevel then
                rank.jobLevel = 0
            end
        end
        department.job = data.job
        UpdateDepartmentSQL(data.departmentId, "job")
        UpdateDepartmentSQL(data.departmentId, "ranks")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "setDepartmentJob",
                departmentId = data.departmentId,
                job = data.job,
            })
        end
        SetTimeout(500, function()
            for k, v in pairs(InManagement) do
                TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                    type = "updateMembers",
                    departmentId = data.departmentId,
                    members = department.members,
                })
            end
        end)
    elseif action == "createDepartment" then
        local jobCfg = Config.PoliceJobs[data.job]
        if not jobCfg then print("ERROR: Job not found: ", data.job) return end
        local leader = data.leader
        local members = {}
        if leader and GetIdentifier(leader) then
            table.insert(members, {
                identifier = GetIdentifier(leader),
                name = GetPlayerCharacterName(leader),
                rankId = 1,
                onDutyTime = 0,
                recentDutyLogs = {},
                permissions = {},
            })
        end

        local department = {
            job = data.job,
            label = data.label,
            image = data.image,
            location = data.location,
            members = members,
            ranks = {
                {
                    rankId = 1,
                    label = _L("default_leader_rank"),
                    jobLevel = jobCfg.maxLevel,
                    managingRankIds = {},
                    armory = {},
                    vehicles = {},
                },
                {
                    rankId = 2,
                    label = _L("default_rank"),
                    jobLevel = 0,
                    managingRankIds = {},
                    armory = {},
                    vehicles = {},
                },
            },
            permissions = {},
            outfits = {},
            locations = {},
            misc = {
                transactions = {},
            },
        }
        MySQL.insert('INSERT INTO `pickle_police_departments` (label, image, job, location, members, ranks, permissions, outfits, locations, misc) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            department.label, department.image, department.job, json.encode(department.location), json.encode(department.members), json.encode(department.ranks), json.encode(department.permissions), json.encode(department.outfits), json.encode(department.locations), json.encode(department.misc)
        }, function(id)
            department.id = id
            InitializeDepartment(id, department)
            for k, v in pairs(InManagement) do
                TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                    type = "createDepartment",
                    department = department,
                })
            end
        end)
    elseif action == "deleteDepartment" then
        MySQL.query('DELETE FROM `pickle_police_departments` WHERE `id` = ?', {
            data.departmentId,
        }, function()
            DeleteDepartment(data.departmentId)
            for k, v in pairs(InManagement) do
                TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                    type = "deleteDepartment",  
                    departmentId = data.departmentId,
                })
            end
        end)
        MySQL.query('DELETE FROM `pickle_police_files` WHERE `departmentId` = ?', {
            data.departmentId,
        })
        MySQL.query('DELETE FROM `pickle_police_fines` WHERE `departmentId` = ?', {
            data.departmentId,
        })
    elseif action == "createLocation" then
        local location = data.location
        local departmentId = data.departmentId
        local department = Departments[departmentId]
        if not department then return end
        local locationId = GenerateUniqueLocationId(departmentId)
        local positions = {}
        for k, v in pairs(location.positions) do
            positions[k] = EnsureDepartmentData("location", v)
        end
        local newLocation = {
            id = locationId,
            type = location.type,
            positions = positions,
            settings = location.settings or {},
        }
        table.insert(department.locations, newLocation)
        UpdateDepartmentSQL(departmentId, "locations")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "createLocation",
                departmentId = departmentId,
                location = newLocation,
            })
        end
        TriggerClientEvent("pickle_policejob:updateDepartment", -1, {
            type = "createLocation",
            departmentId = departmentId,
            location = newLocation,
        })
    elseif action == "updateLocation" then
        local location
        for i=1, #department.locations do
            if department.locations[i].id == data.locationId then
                location = department.locations[i]
                break
            end
        end
        if not location then return end
        location.positions = data.location.positions
        location.settings = data.location.settings
        for k, v in pairs(location.positions) do
            location.positions[k] = EnsureDepartmentData("location", v)
        end
        UpdateDepartmentSQL(departmentId, "locations")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "updateLocation",
                departmentId = departmentId,
                locationId = data.locationId,
                pointId = data.pointId,
                location = location,
            })
        end
        TriggerClientEvent("pickle_policejob:updateDepartment", -1, {
            type = "updateLocation",
            departmentId = departmentId,
            locationId = data.locationId,
            location = location,
        })
    elseif action == "deleteLocation" then
        local location
        for i=1, #department.locations do
            if department.locations[i].id == data.locationId then
                location = {index = i, data = department.locations[i]}
                break
            end
        end
        if not location then return end
        table.remove(department.locations, location.index)
        UpdateDepartmentSQL(departmentId, "locations")
        for k, v in pairs(InManagement) do
            TriggerClientEvent("pickle_policejob:updateManagement", tonumber(k), {
                type = "deleteLocation",
                departmentId = departmentId,
                locationId = data.locationId,
            })
        end
        TriggerClientEvent("pickle_policejob:updateDepartment", -1, {
            type = "deleteLocation",
            departmentId = departmentId,
            locationId = data.locationId,
        })
    end
    ConfigSV.WebhookHandler("management", {
        action = action,
        department = department.label,
        player = GetPlayerCharacterName(source) .. " (ID: " .. source .. " / " .. GetPlayerIdentifier(source) .. ")",
        data = "```json\n" .. json.encode(data) .. "\n```",
    })
end)

RegisterNetEvent("pickle_policejob:closeManagement", function()
    InManagement[source] = nil
end)

RegisterCommand("managepd", function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    InManagement[source] = true
    TriggerClientEvent("pickle_policejob:openManagement", source, GetManagementData())
end)