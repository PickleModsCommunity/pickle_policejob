function GetDepartmentMemberArmory(source)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    local armory = {}
    for i=1, #Config.PoliceArmory do
        local allowed = false
        print(departmentId, member.rankId, Config.PoliceArmory[i].name, "armory")
        if CanRankAccessEntry(departmentId, member.rankId, Config.PoliceArmory[i].name, "armory") then
            allowed = true
        elseif CanPermissionsAccessEntry(departmentId, member.permissions, Config.PoliceArmory[i].name, "armory") then
            allowed = true
        end
        if allowed then
            table.insert(armory, Config.PoliceArmory[i])
        end
    end
    return #armory > 0 and armory or nil, _L("no_armory_access")
end

function CanPlayerBuyArmoryItem(source, itemName, quantity)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return false end
    local department = GetDepartment(departmentId)
    if not department then return false end
    local armory = GetDepartmentMemberArmory(source) or {}
    for i=1, #armory do
        if armory[i].name == itemName then
            return true
        end
    end
    return false
end

RegisterNetEvent("pickle_policejob:buyArmoryItem", function(data)
    local source = source
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    if not CanPlayerBuyArmoryItem(source, data.itemName, data.quantity) then return ShowNotification(source, _L("no_permission")) end
    local item
    for i=1, #Config.PoliceArmory do
        if Config.PoliceArmory[i].name == data.itemName then
            item = Config.PoliceArmory[i]
            break
        end
    end
    if not item then return ShowNotification(source, _L("ERR_NOT_FOUND")) end
    if data.quantity <= 0 or data.quantity > item.maxCount then return ShowNotification(source, _L("cant_get_this_amount")) end
    local newCount = Inventory.GetItemCount(source, item.name) + data.quantity
    if newCount > item.maxCount then return ShowNotification(source, _L("cant_get_this_amount")) end
    local price = item.price * data.quantity
    if price > 0 then
        local money = GetMoney(source)
        if money < price then return ShowNotification(source, _L("not_enough_money", NumberWithCommas(price - money))) end
        RemoveMoney(source, price)
    end
    Inventory.AddItem(source, item.name, data.quantity)
    ShowNotification(source, _L("armory_purchased", GetItemLabel(item.name), data.quantity))
end)

lib.callback.register("pickle_policejob:openArmory", function(source)
    return GetDepartmentMemberArmory(source)
end)