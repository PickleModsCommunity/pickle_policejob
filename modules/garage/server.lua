function GetDepartmentMemberGarage(source, garageType)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    local garage = {}
    for i=1, #Config.PoliceGarage do
        local allowed = false
        if Config.PoliceGarage[i].garageType == garageType then
            if CanRankAccessEntry(departmentId, member.rankId, Config.PoliceGarage[i].model, "vehicles") then
                allowed = true
            elseif CanPermissionsAccessEntry(departmentId, member.permissions, Config.PoliceGarage[i].model, "vehicles") then
                allowed = true
            end
            if allowed then
                table.insert(garage, Config.PoliceGarage[i])
            end
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

lib.callback.register('pickle_policejob:openGarage', function(source, garageType)
    return GetDepartmentMemberGarage(source, garageType)
end)

lib.callback.register('pickle_policejob:getVehicleMods', function(source, model)
    if not (Config.Garage and Config.Garage.PersistVehicleMods) then return nil end
    if not source or not model then return nil end
    local identifier = GetIdentifier(source)
    if not identifier or identifier == "" then
        print(("[pickle_policejob] Skipping vehicle mod fetch: no identifier for source %s"):format(tostring(source)))
        return nil
    end
    local result = MySQL.query.await("SELECT mods FROM pickle_police_vehicle_mods WHERE identifier = ? AND model = ?", {
        identifier, tostring(model),
    })
    if not result or not result[1] or not result[1].mods then return nil end
    local ok, decoded = pcall(json.decode, result[1].mods)
    if not ok then return nil end
    return decoded
end)

RegisterNetEvent('pickle_policejob:saveVehicleMods', function(model, mods)
    local source = source
    if not (Config.Garage and Config.Garage.PersistVehicleMods) then return end
    if not source or not model or type(mods) ~= "table" then return end
    local identifier = GetIdentifier(source)
    if not identifier or identifier == "" then
        print(("[pickle_policejob] Skipping vehicle mod save: no identifier for source %s"):format(tostring(source)))
        return
    end
    local encoded = json.encode(mods)
    if not encoded then return end
    MySQL.query("INSERT INTO pickle_police_vehicle_mods (identifier, model, mods) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE mods = VALUES(mods)", {
        identifier, tostring(model), encoded,
    })
end)

MySQL.ready(function()
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_vehicle_mods (identifier VARCHAR(255) NOT NULL, model VARCHAR(64) NOT NULL, mods LONGTEXT NOT NULL, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (identifier, model))")
end)

lib.callback.register('pickle_policejob:takeVehicle', function(source, model, garageType)
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId or not member then return end
    local department = GetDepartment(departmentId)
    if not department then return end
    local garage, err = GetDepartmentMemberGarage(source, garageType) or {}
    local garageVehicle = nil
    for i=1, #garage do
        if garage[i].model == model then
            garageVehicle = garage[i]
        end
    end
    if not garageVehicle then return false, err end
    if garageVehicle.price and garageVehicle.price > 0 then
        if not Config.Finance.deductCostsFromDepartment then
            local money = GetMoney(source)
            if money < garageVehicle.price then return false, _L("not_enough_money", NumberWithCommas(garageVehicle.price - money)) end
            RemoveMoney(source, garageVehicle.price)
        else
            local money = GetDepartmentMoney(departmentId)
            if money < garageVehicle.price then return false, _L("department_not_enough_money", NumberWithCommas(garageVehicle.price - money)) end
            RemoveDepartmentMoney(departmentId, garageVehicle.price)
            AddDepartmentTransaction(departmentId, source, "withdraw", garageVehicle.price, _L("transaction_garage_purchase", garageVehicle.label))
        end
    end
    return true
end)