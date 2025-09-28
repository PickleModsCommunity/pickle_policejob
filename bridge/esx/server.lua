if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function RegisterUsableItem(...)
    ESX.RegisterUsableItem(...)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(tonumber(source))
    if not xPlayer or not xPlayer.identifier then return end
    return xPlayer.identifier
end

function GetSourceFromIdentifier(identifier)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    return xPlayer and xPlayer.source or nil
end

function GetPlayerCharacterName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return "ERR_UNK_NAME" end
    return xPlayer.getName()
end

function GetPlayerDateOfBirth(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return "Unknown" end
    return xPlayer.get('dateofbirth')
end

function GetPlayerGender(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return "Unknown" end
    return xPlayer.sex == 0 and _L("male") or _L("female")
end

function CanAccessGroup(source, data)
    if not data then return true end
    local pdata = ESX.GetPlayerFromId(source)
    for k,v in pairs(data.jobs) do 
        if (pdata.job.name == k and pdata.job.grade >= v) then return true end
    end
    return false
end 

function CheckPermission(source, permission)
    if permission.ignorePermissions then return true end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade
    local group = xPlayer.getGroup()
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #(permission.groups or {}) do 
        if group == permission.groups[i] then 
            return true 
        end
    end
end

function AddMoney(source, count, currency)
    local xPlayer = ESX.GetPlayerFromId(source)
    local currency = currency or "money"
    if (currency == "money") then
        xPlayer.addMoney(count)
    elseif (currency == "bank") then
        xPlayer.addAccountMoney("bank", count)
    elseif (currency == "dirty") then
        xPlayer.addAccountMoney("black_money", count)
    end
    TriggerClientEvent("pickle_policejob:updateMoney", source, GetMoney(source, currency))
end

function RemoveMoney(source, count, currency)
    local xPlayer = ESX.GetPlayerFromId(source)
    local currency = currency or "money"
    if (currency == "money") then
        xPlayer.removeMoney(count)
    elseif (currency == "bank") then
        xPlayer.removeAccountMoney("bank", count)
    elseif (currency == "dirty") then
        xPlayer.removeAccountMoney("black_money", count)
    end
    TriggerClientEvent("pickle_policejob:updateMoney", source, GetMoney(source, currency))
end

function GetMoney(source, currency)
    local xPlayer = ESX.GetPlayerFromId(source)
    local currency = currency or "money"
    local money = 0
    if (currency == "money") then
        money = xPlayer.getMoney()
    elseif (currency == "bank") then
        money = xPlayer.getAccount("bank").money
    elseif (currency == "dirty") then
        money = xPlayer.getAccount("black_money").money
    end    
    TriggerClientEvent("pickle_policejob:updateMoney", source, money)
    return money
end

function ImpoundVehiclePlate(plate)
    MySQL.query("UPDATE owned_vehicles SET stored = 0 WHERE plate = ?", { plate })
end

function GetOwnedVehicleFromPlate(plate)
    local data = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate=@plate;", {
        ['@plate'] = plate,
    })[1]
    return data and {owner = data.owner} or nil 
end

function AddOwnedVehicle(source, plate, model)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle);", {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = plate,
        ['@vehicle'] = json.encode({
            plate = toupper(plate),
            model = joaat(model),
        }),
    })
end

function UpdateVehiclePlate(source, plate, newPlate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute("UPDATE owned_vehicles SET plate=@newPlate WHERE owner=@owner AND plate=@plate;", {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = plate,
        ['@newPlate'] = newPlate,
    })
end

function GetPlayerJob(source)
    local xPlayer = ESX.GetPlayerFromId(tonumber(source))
    if not xPlayer then return "Unknown Job", "Unknown Grade" end
    return {name = xPlayer.job.name, label = xPlayer.job.label, rank_label = xPlayer.job.grade_label}
end

function SetPlayerJob(source, job, grade)
    local xPlayer = ESX.GetPlayerFromId(tonumber(source))
    if not xPlayer then return end
    xPlayer.setJob(job, grade)
end

function SetPlayerFrameworkDuty(source, onDuty)
    local xPlayer = ESX.GetPlayerFromId(tonumber(source))
    if not xPlayer then return end
    local jobName, jobGrade = GetPlayerDepartmentJob(source)
    if not jobName or (not onDuty and not Config.DefaultJob.usePrefixDuty) then return xPlayer.setJob("unemployed", 0) end
    xPlayer.setJob((onDuty and "" or "off")..jobName, jobGrade)
end

function IsPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    for i=1, #Config.AdminGroups do 
        if group == Config.AdminGroups[i] then
            return true 
        end
    end
    return false
end

function AddSocietyMoney(name, amount)
    TriggerEvent('esx_addonaccount:getSharedAccount', "society_"..name, function(account)
        account.addMoney(amount)
    end)
end

function AddOwnedVehicle(source, model)
    local xPlayer = ESX.GetPlayerFromId(source)
    local plate = ""
    local letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
    local numbers = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
    for i = 1, 3 do
        plate = plate .. letters[math.random(1, #letters)]
    end
    plate = plate .. " "
    for i = 1, 3 do
        plate = plate .. numbers[math.random(1, #numbers)]
    end
    MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle);", {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = plate,
        ['@vehicle'] = json.encode({
            plate = toupper(plate),
            model = joaat(model),
        }),
    })
end

function GetPlayerStatus(source)
    local p = promise.new()
    local maxValue = 1000000
    TriggerEvent("esx_status:getStatus", source, 'drunk', function(status)
        p:resolve(0.40 * (status.val / maxValue))
    end)
    local bac = Citizen.Await(p)
    return {Alcohol = math.floor(bac * 100) / 100}
end

AddEventHandler('esx:setJob', function(source, job, lastJob)
    EnsurePlayerDuty(source)
end)

-- Inventory Fallback

CreateThread(function()
    Wait(100)

    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
    
    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.CanCarryItem = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.InventoryLimit then 
            local item = xPlayer.getInventoryItem(name)
            return (item.limit >= item.count + count)
        else 
            return xPlayer.canCarryItem(name, count)
        end
    end

    Inventory.GetInventory = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local items = {}
        local data = xPlayer.getInventory()
        for i=1, #data do 
            local item = data[i]
            if item then
                items[#items + 1] = {
                    name = item.name,
                    label = item.label,
                    count = item.count,
                    weight = item.weight,
                    slot = -1,
                    metadata = {}
                }
            end
        end
        return items
    end

    Inventory.UpdateInventory = function(source)
        SetTimeout(1000, function()
            TriggerClientEvent("pickle_policejob:updateInventory", source, Inventory.GetInventory(source))
        end)
    end

    Inventory.AddItem = function(source, name, count, metadata) -- Metadata is not required.
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addInventoryItem(name, count)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveItem = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem(name, count)
        Inventory.UpdateInventory(source)
    end

    Inventory.AddWeapon = function(source, name, count, metadata) -- Metadata is not required.
        if Config.WeaponsAreItems then 
            Inventory.AddItem(source, name, count, metadata)
            return
        end
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addWeapon(name, 0)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveWeapon = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeWeapon(name, 0)
        Inventory.UpdateInventory(source)
    end

    Inventory.GetItemCount = function(source, name)
        local xPlayer = ESX.GetPlayerFromId(source)
        local item = xPlayer.getInventoryItem(name)
        return item and item.count or 0
    end

    Inventory.HasWeapon = function(source, name, count)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.hasWeapon(name)
    end

    lib.callback.register("pickle_policejob:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    if GetResourceState("ox_inventory") == "started" then 
        for item, data in pairs(exports.ox_inventory:Items()) do
            Inventory.Items[item] = {label = data.label}
        end
        Inventory.Ready = true
    elseif GetResourceState("qs-inventory") == "started" then 
        for item, data in pairs(exports['qs-inventory']:GetItemList()) do
            Inventory.Items[item] = {label = data.label}
        end
        Inventory.Ready = true
    else
        MySQL.ready(function() 
            MySQL.Async.fetchAll("SELECT * FROM items;", {}, function(results) 
                for i=1, #results do 
                    Inventory.Items[results[i].name] = {label = results[i].label}
                end
                Inventory.Ready = true
            end)
        end)
    end
end)