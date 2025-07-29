RegisterCommand("bodycam", function(source, args, rawCommand)
    local target = tonumber(args[1])
    -- if not target or source == target then return end
    local targetPed = GetPlayerPed(target)
    if not targetPed or targetPed == 0 then return end
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)
    local departmentId, memberData = GetPlayerDepartment(target)
    if not departmentId then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    local rank = GetDepartmentRank(departmentId, memberData.rankId)
    if not rank then return end
    TriggerClientEvent("pickle_policejob:bodycam:startView", source, target, {
        coords = targetCoords,
        heading = targetHeading,
        rank = rank.label or "Unknown",
        department = department.label or "Unknown",
        name = GetPlayerCharacterName(target) or "Unknown",
    })
end)