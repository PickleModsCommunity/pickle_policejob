local BodycamSessions = {}

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
    if Config.Bodycam.item.required and Inventory.GetItemCount(target, Config.Bodycam.item.name) < 1 then return end
    if not BodycamSessions[target] then
        BodycamSessions[target] = {}
        CreateThread(function()
            if not Config.Bodycam.item.required then return end
            while BodycamSessions[target] do
                Wait(5000)
                if not BodycamSessions[target] then break end
                if Inventory.GetItemCount(target, Config.Bodycam.item.name) < 1 then
                    for i=1, #BodycamSessions[target] do
                        TriggerClientEvent("pickle_policejob:bodycam:stopView", BodycamSessions[target][i])
                    end
                    BodycamSessions[target] = nil
                    break
                end
            end
        end)
    end
    local added = false
    for i=1, #BodycamSessions[target] do
        if BodycamSessions[target][i] == source then
            added = true
        end
    end
    if not added then
        table.insert(BodycamSessions[target], source)
    end

    TriggerClientEvent("pickle_policejob:bodycam:startView", source, target, {
        coords = targetCoords,
        heading = targetHeading,
        rank = rank.label or "Unknown",
        department = department.label or "Unknown",
        name = GetPlayerCharacterName(target) or "Unknown",
    })
    return true
end)

RegisterNetEvent("pickle_policejob:bodycam:stopView", function()
    local source = source
    for k,v in pairs(BodycamSessions) do
        for i=1, #v do
            if v[i] == source then
                table.remove(v, i)
                break
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local player = source
    for k,v in pairs(BodycamSessions) do
        for i=1, #v do
            if v[i] == player then
                table.remove(v, i)
                break
            end
        end
    end
end)