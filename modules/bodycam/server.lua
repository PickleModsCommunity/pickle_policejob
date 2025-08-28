RegisterCommand("bodycam", function(source, args, rawCommand)

end)

lib.callback.register("pickle_policejob:bodycam:startView", function(source, identifier)
    local departmentId = GetPlayerDepartment(source)
    local member, _, target = GetDepartmentMember(departmentId, identifier)
    if not member or not target or target < 1 then return end
    local targetPed = GetPlayerPed(target)
    if not targetPed or targetPed == 0 then return end
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)
    local department = GetDepartment(departmentId)
    local rank = GetDepartmentRank(departmentId, member.rankId)
    TriggerClientEvent("pickle_policejob:bodycam:startView", source, target, {
        coords = targetCoords,
        heading = targetHeading,
        rank = rank.label or "Unknown",
        department = department.label or "Unknown",
        name = GetPlayerCharacterName(target) or "Unknown",
    })
    return true
end)