local IN_COMPUTER = {}

function GenerateUniqueRankId(departmentId)
    local uniqueRankId = 1
    local department = Departments[departmentId]
    if not department then return end
    for i=1, #department.ranks do
        if department.ranks[i].rankId >= uniqueRankId then
            uniqueRankId = department.ranks[i].rankId + 1
        end
    end
    return uniqueRankId
end

function SendComputerEvent(event, ...)
    for k, v in pairs(IN_COMPUTER) do
        TriggerClientEvent(event, tonumber(k), ...)
    end
end

lib.callback.register("pickle_policejob:openComputer", function(source)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId then return nil, _L("not_in_department") end
    local department = Departments[departmentId]
    if not department then return nil, "ERROR_DEPARTMENT_NOT_FOUND" end
    if not IsPlayerOnDuty(source) then return nil, _L("not_on_duty") end
    IN_COMPUTER[source] = true
    return {
        department = department,
        backgroundImage = "/nui/images/computer_background.png",
    }
end)

lib.callback.register("pickle_policejob:getNearbyPlayers", function(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local nearby = {}
    for k, v in pairs(GetPlayers()) do
        local targetPed = GetPlayerPed(v)
        if targetPed ~= ped then 
            local targetCoords = GetEntityCoords(targetPed)
            if #(coords - targetCoords) < 10.0 then 
                nearby[#nearby + 1] = {
                    source = tonumber(v),
                    identifier = GetIdentifier(v),
                    name = GetPlayerCharacterName(v),
                }
            end
        end
    end 
    return nearby
end)

RegisterNetEvent("pickle_policejob:closeComputer", function()
    IN_COMPUTER[source] = nil
end)

RegisterNetEvent("pickle_policejob:updateComputerDepartment", function(updateType, data)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId then return end
    local department = Departments[departmentId]
    if not department then return end
    if updateType == "addMember" then
        if not CanRankManageRank(departmentId, member.rankId, department.ranks[#department.ranks].rankId) then return ShowNotification(source, _L("no_permission")) end
        local characterName = GetPlayerCharacterName(data.source)
        if characterName == "ERR_UNK_NAME" then return ShowNotification(data.source, _L("player_not_found")) end
        local targetDepartmentId, targetMember = GetPlayerDepartment(data.source)
        if targetDepartmentId then return ShowNotification(data.source, _L("player_in_department")) end
        table.insert(department.members, {
            identifier = GetIdentifier(data.source),
            name = characterName,
            rankId = department.ranks[#department.ranks].rankId,
            recentDutyLogs = {},
            permissions = {},
            onDutyTime = 0,
        })
        UpdateDepartmentSQL(departmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
        ShowNotification(source, _L("member_added", characterName))
        ShowNotification(data.source, _L("you_have_been_added_to_department", department.name))
        SetPlayerDuty(data.source, true)
    elseif updateType == "removeMember" then
        local targetDepartmentId, targetMember = GetIdentifierDepartment(data.identifier)
        if not targetDepartmentId then return ShowNotification(source, _L("player_not_in_department")) end
        if targetDepartmentId ~= departmentId then return ShowNotification(source, _L("player_in_department")) end
        if not CanRankManageRank(departmentId, member.rankId, targetMember.rankId) then return ShowNotification(source, _L("no_permission")) end
        local targetId = GetSourceFromIdentifier(data.identifier)
        if targetId then
            SetPlayerDuty(targetId, false)
            ShowNotification(targetId, _L("you_have_been_removed_from_department"))
        end
        for i=1, #department.members do
            if department.members[i].identifier == data.identifier then
                table.remove(department.members, i)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
        ShowNotification(source, _L("member_removed", member.name))
    elseif updateType == "addRank" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        local rankId = GenerateUniqueRankId(departmentId)
        table.insert(department.ranks, {
            rankId = rankId,
            salary = data.salary or 0,
            label = data.label,
            jobLevel = data.jobLevel or 0,
            managingRankIds = {},
            armory = {},
            vehicles = {},
        })
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
        ShowNotification(source, _L("rank_added", data.label))
    elseif updateType == "deleteRank" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_delete_leader_rank")) end
        if #department.ranks - 1 == 1 then return ShowNotification(source, _L("cannot_delete_last_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                table.remove(department.ranks, i)
                break
            end
        end
        for i=1, #department.members do
            if department.members[i].rankId == data.rankId then
                department.members[i].rankId = department.ranks[#department.ranks].rankId
            end
        end
        UpdateDepartmentSQL(departmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
        SetTimeout(500, function()
            UpdateDepartmentSQL(departmentId, "ranks")
            SendComputerEvent("pickle_policejob:updateComputerDepartment", {
                type = "updateRanks",
                ranks = department.ranks,
            })
        end)
        ShowNotification(source, _L("rank_deleted", data.label))
    elseif updateType == "moveRank" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        local rank, rankIndex = GetDepartmentRank(departmentId, data.rankId)
        if not rank then return ShowNotification(source, _L("rank_not_found")) end
        if rank.rankId == department.ranks[1].rankId then return ShowNotification(source, _L("cannot_move_leader_rank")) end
        if data.up and rankIndex == 2 then return ShowNotification(source, _L("cannot_move_leader_rank")) end
        if not data.up and rankIndex == #department.ranks then return ShowNotification(source, _L("cannot_move_last_rank")) end
        table.remove(department.ranks, rankIndex)
        if data.up then
            table.insert(department.ranks, rankIndex - 1, rank)
        else
            table.insert(department.ranks, rankIndex + 1, rank)
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "updateMemberRank" then
        local targetDepartmentId, targetMember = GetIdentifierDepartment(data.identifier)
        if not targetDepartmentId then return ShowNotification(source, _L("player_not_in_department")) end
        if targetDepartmentId ~= departmentId then return ShowNotification(source, _L("player_in_department")) end
        if not CanRankManageRank(departmentId, member.rankId, targetMember.rankId) then return ShowNotification(source, _L("no_permission")) end
        if not CanRankManageRank(departmentId, member.rankId, data.rankId) then return ShowNotification(source, _L("no_permission")) end
        for i=1, #department.members do
            if department.members[i].identifier == data.identifier then
                department.members[i].rankId = data.rankId
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
        local newRank, newRankIndex = GetDepartmentRank(departmentId, data.rankId)
        ShowNotification(source, _L("member_rank_updated", member.name, newRank.label))
    elseif updateType == "addPermission" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.permissions[data.label] then return ShowNotification(source, _L("permission_already_exists")) end
        department.permissions[data.label] = {
            managingRankIds = {},
            armory = {},
            vehicles = {},
        }
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
        ShowNotification(source, _L("permission_added", data.label))
    elseif updateType == "deletePermission" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.label] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.members do
            for j=1, #department.members[i].permissions do
                if department.members[i].permissions[j] == data.label then
                    table.remove(department.members[i].permissions, j)
                    break
                end
            end
        end
        UpdateDepartmentSQL(departmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
        SetTimeout(500, function()
            department.permissions[data.label] = nil
            UpdateDepartmentSQL(departmentId, "permissions")
            SendComputerEvent("pickle_policejob:updateComputerDepartment", {
                type = "updatePermissions",
                permissions = department.permissions,
            })
        end)
        ShowNotification(source, _L("permission_deleted", data.label))
    elseif updateType == "addPermissionRankManager" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].managingRankIds do
            if department.permissions[data.permission].managingRankIds[i] == data.managingRankId then
                return ShowNotification(source, _L("rank_manager_already_added"))
            end
        end
        table.insert(department.permissions[data.permission].managingRankIds, data.managingRankId)
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
    elseif updateType == "deletePermissionRankManager" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].managingRankIds do
            if department.permissions[data.permission].managingRankIds[i] == data.managingRankId then
                table.remove(department.permissions[data.permission].managingRankIds, i)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
    elseif updateType == "addPermissionArmory" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].armory do
            if department.permissions[data.permission].armory[i] == data.item then
                return ShowNotification(source, _L("armory_item_already_added"))
            end
        end
        table.insert(department.permissions[data.permission].armory, data.item)
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
    elseif updateType == "deletePermissionArmory" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].armory do
            if department.permissions[data.permission].armory[i] == data.item then
                table.remove(department.permissions[data.permission].armory, i)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
    elseif updateType == "addPermissionVehicle" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].vehicles do
            if department.permissions[data.permission].vehicles[i] == data.vehicle then
                return ShowNotification(source, _L("vehicle_already_added"))
            end
        end
        table.insert(department.permissions[data.permission].vehicles, data.vehicle)
        UpdateDepartmentSQL(departmentId, "permissions")
        for k, v in pairs(IN_COMPUTER) do
            TriggerClientEvent("pickle_policejob:updateComputerDepartment", tonumber(k), {
                type = "updatePermissions",
                permissions = department.permissions,
            })
        end
    elseif updateType == "deletePermissionVehicle" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not department.permissions[data.permission] then return ShowNotification(source, _L("permission_not_found")) end
        for i=1, #department.permissions[data.permission].vehicles do
            if department.permissions[data.permission].vehicles[i] == data.vehicle then
                table.remove(department.permissions[data.permission].vehicles, i)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "permissions")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updatePermissions",
            permissions = department.permissions,
        })
    elseif updateType == "addMemberPermission" then
        local targetDepartmentId, targetMember = GetIdentifierDepartment(data.identifier)
        if not targetDepartmentId then return ShowNotification(source, _L("player_not_in_department")) end
        if targetDepartmentId ~= departmentId then return ShowNotification(source, _L("player_in_department")) end
        if not CanRankManageRank(departmentId, member.rankId, targetMember.rankId) then return ShowNotification(source, _L("no_permission")) end
        if not CanRankManagePermission(departmentId, member.rankId, data.label) then return ShowNotification(source, _L("no_permission")) end
        local found = false
        for i=1, #targetMember.permissions do
            if targetMember.permissions[i] == data.label then
                found = true
                break
            end
        end
        if found then return ShowNotification(source, _L("permission_already_added")) end
        table.insert(targetMember.permissions, data.label)
        UpdateDepartmentSQL(targetDepartmentId, "members")
        for k, v in pairs(IN_COMPUTER) do
            TriggerClientEvent("pickle_policejob:updateComputerDepartment", tonumber(k), {
                type = "updateMembers",
                members = department.members,
            })
        end
    elseif updateType == "deleteMemberPermission" then
        local targetDepartmentId, targetMember = GetIdentifierDepartment(data.identifier)
        if not targetDepartmentId then return ShowNotification(source, _L("player_not_in_department")) end
        if targetDepartmentId ~= departmentId then return ShowNotification(source, _L("player_in_department")) end
        if not CanRankManageRank(departmentId, member.rankId, targetMember.rankId) then return ShowNotification(source, _L("no_permission")) end
        if not CanRankManagePermission(departmentId, member.rankId, data.label) then return ShowNotification(source, _L("no_permission")) end
        local found = false
        for i=1, #targetMember.permissions do
            if targetMember.permissions[i] == data.label then
                found = true
                table.remove(targetMember.permissions, i)
                break
            end
        end
        if not found then return ShowNotification(source, _L("permission_not_found")) end
        UpdateDepartmentSQL(targetDepartmentId, "members")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateMembers",
            members = department.members,
        })
    elseif updateType == "updateRankLabel" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                department.ranks[i].label = data.label
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "updateRankJobLevel" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                department.ranks[i].jobLevel = data.jobLevel
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "updateRankSalary" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if not data.salary or not tonumber(data.salary) then data.salary = 0 end
        if data.salary <= 0 then data.salary = 0 end
        if data.salary > Config.Finance.maxRankSalary then data.salary = Config.Finance.maxRankSalary end
        local rank
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                department.ranks[i].salary = data.salary
                rank = department.ranks[i]
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
        ShowNotification(source, _L("salary_updated", rank.label, NumberWithCommas(data.salary)))
    elseif updateType == "addRankManager" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                table.insert(department.ranks[i].managingRankIds, data.managingRankId)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "deleteRankManager" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                for j=1, #department.ranks[i].managingRankIds do
                    if department.ranks[i].managingRankIds[j] == data.managingRankId then
                        table.remove(department.ranks[i].managingRankIds, j)
                        break
                    end
                end
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "addRankArmory" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                for j=1, #department.ranks[i].armory do
                    if department.ranks[i].armory[j] == data.item then
                        return ShowNotification(source, _L("armory_item_already_added"))
                    end
                end
                table.insert(department.ranks[i].armory, data.item)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "deleteRankArmory" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                for j=1, #department.ranks[i].armory do
                    if department.ranks[i].armory[j] == data.item then
                        table.remove(department.ranks[i].armory, j)
                        break
                    end
                end
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "addRankVehicle" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                for j=1, #department.ranks[i].vehicles do
                    if department.ranks[i].vehicles[j] == data.vehicle then
                        return ShowNotification(source, _L("vehicle_already_added"))
                    end
                end
                table.insert(department.ranks[i].vehicles, data.vehicle)
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "deleteRankVehicle" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if department.ranks[1].rankId == data.rankId then return ShowNotification(source, _L("cannot_update_leader_rank")) end
        for i=1, #department.ranks do
            if department.ranks[i].rankId == data.rankId then
                for j=1, #department.ranks[i].vehicles do
                    if department.ranks[i].vehicles[j] == data.vehicle then
                        table.remove(department.ranks[i].vehicles, j)
                        break
                    end
                end
                break
            end
        end
        UpdateDepartmentSQL(departmentId, "ranks")
        SendComputerEvent("pickle_policejob:updateComputerDepartment", {
            type = "updateRanks",
            ranks = department.ranks,
        })
    elseif updateType == "exchangeDepartmentFunds" then
        if not IsPlayerDepartmentLeader(source) then return ShowNotification(source, _L("no_permission")) end
        if data.amount <= 0 then return ShowNotification(source, _L("invalid_amount")) end
        if data.withdraw then
            if department.money < data.amount then return ShowNotification(source, _L("department_not_enough_money", NumberWithCommas(data.amount - department.money))) end
            RemoveDepartmentMoney(departmentId, data.amount)
            AddMoney(source, data.amount)
            AddDepartmentTransaction(departmentId, source, "withdraw", data.amount, _L("finance_withdraw"))
            SendComputerEvent("pickle_policejob:updateComputerDepartment", {
                type = "updateFinance",
                money = department.money,
            })
            ShowNotification(source, _L("finance_withdrew", NumberWithCommas(data.amount)))
        else
            local money = GetMoney(source)
            if money < data.amount then return ShowNotification(source, _L("not_enough_money", NumberWithCommas(data.amount - money))) end
            AddDepartmentMoney(departmentId, data.amount)
            RemoveMoney(source, data.amount)
            AddDepartmentTransaction(departmentId, source, "deposit", data.amount, _L("finance_deposit"))
            SendComputerEvent("pickle_policejob:updateComputerDepartment", {
                type = "updateFinance",
                money = department.money,
            })
            ShowNotification(source, _L("finance_deposited", NumberWithCommas(data.amount)))
        end
    end
    ConfigSV.WebhookHandler("computer", {
        updateType = updateType,
        player = GetPlayerCharacterName(source) .. " (ID: " .. source .. " / " .. GetPlayerIdentifier(source) .. ")",
        department = department.label,
        data = "```json\n" .. json.encode(data) .. "\n```",
    })
end)