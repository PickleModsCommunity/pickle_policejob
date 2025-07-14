local InManagement = {}

function GetManagementData()
    local departments = {}
    for id, department in pairs(Departments) do
        departments[#departments + 1] = {
            id = id,
            label = department.label,
            location = department.location,
            locations = department.locations,
            members = department.members,
            ranks = department.ranks,
        }
    end
    return {
        departments = departments,
    }
end

RegisterNetEvent("pickle_policejob:managementAction", function(action, data)
    local department
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
    elseif action == "createDepartment" then
        local leader = data.leader
        local members = {}
        if leader and GetIdentifier(leader) then
            table.insert(members, {
                identifier = GetIdentifier(leader),
                name = GetPlayerCharacterName(leader),
                rankId = 1,
                recentDutyLogs = {},
                permissions = {},
            })
        end

        local department = {
            label = data.label,
            location = data.location,
            members = members,
            ranks = {
                {
                    rankId = 1,
                    label = _L("default_rank_name"),
                    managingRankIds = {},
                }
            },
            permissions = {},
            outfits = {},
            locations = {},
            misc = {},
        }
        MySQL.insert('INSERT INTO `pickle_police_departments` (label, location, members, ranks, permissions, outfits, locations, misc) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            department.label, department.location, json.encode(department.members), json.encode(department.ranks), json.encode(department.permissions), json.encode(department.outfits), json.encode(department.locations), json.encode(department.misc)
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
    end
end)

RegisterNetEvent("pickle_policejob:closeManagement", function()
    InManagement[source] = nil
end)

RegisterCommand("managepd", function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    InManagement[source] = true
    TriggerClientEvent("pickle_policejob:openManagement", source, GetManagementData())
end)