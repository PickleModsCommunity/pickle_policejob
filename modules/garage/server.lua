function GetDepartmentMemberGarage(source)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    local garage = {}
    for i=1, #Config.PoliceGarage do
        local allowed = false
        if CanRankAccessEntry(departmentId, member.rankId, Config.PoliceGarage[i].model, "vehicles") then
            allowed = true
        elseif CanPermissionsAccessEntry(departmentId, member.permissions, Config.PoliceGarage[i].model, "vehicles") then
            allowed = true
        end
        if allowed then
            table.insert(garage, Config.PoliceGarage[i])
        end
    end
    return #garage > 0 and garage or nil, _L("no_garage_access")
end

function CanPlayerBuyVehicle(source, model)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return false end
    local department = GetDepartment(departmentId)
    if not department then return false end
    local garage = GetDepartmentMemberGarage(source) or {}
    for i=1, #garage do
        if garage[i].model == model then
            return true
        end
    end
    return false
end

RegisterNetEvent("pickle_policejob:buyVehicle", function(data)
    local source = source
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    if not CanPlayerBuyVehicle(source, data.model) then return ShowNotification(source, _L("no_permission")) end
    local item
    for i=1, #Config.PoliceGarage do
        if Config.PoliceGarage[i].model == data.model then
            item = Config.PoliceGarage[i]
            break
        end
    end
    if not item then return ShowNotification(source, _L("ERR_NOT_FOUND")) end
    local price = item.price
    if price > 0 then
        local money = GetMoney(source)
        if money < price then return ShowNotification(source, _L("not_enough_money", NumberWithCommas(price - money))) end
        RemoveMoney(source, price)
    end
    ShowNotification(source, _L("garage_purchased", GetItemLabel(item.name), data.quantity))
end)

RegisterCallback("pickle_policejob:openGarage", function(source, cb)
    cb(GetDepartmentMemberGarage(source))
end)