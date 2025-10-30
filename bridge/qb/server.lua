if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()
ExternalStatus = { Alcohol = {} }

function RegisterUsableItem(...)
    QBCore.Functions.CreateUseableItem(...)
end

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))?.PlayerData
    if not xPlayer or not xPlayer.citizenid then return end
    return xPlayer.citizenid 
end

function GetSourceFromIdentifier(identifier)
    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
    return xPlayer and xPlayer?.PlayerData.source or nil
end

function GetPlayerCharacterName(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer or not xPlayer.PlayerData then return "ERR_UNK_NAME" end
    return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
end

function CanAccessGroup(source, data)
    if not data then return true end
    local pdata = QBCore.Functions.GetPlayer(tonumber(source)).PlayerData
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade.level >= v) then return true end
    end
    return false
end

function CheckPermission(source, permission)
    if permission.ignorePermissions then return true end
    local source = tonumber(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))?.PlayerData
    if not xPlayer then return end
    local name = xPlayer.job.name
    local rank = xPlayer.job.grade.level
    if permission.jobs[name] and permission.jobs[name] <= rank then 
        return true
    end
    for i=1, #(permission.groups or {}) do 
        if QBCore.Functions.HasPermission(source, permission.groups[i]) then 
            return true 
        end
    end
end

function AddMoney(source, count, currency)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    local currency = currency or "money"
    if (currency == "money") then
        xPlayer.Functions.AddMoney('cash', count)
    elseif (currency == "bank") then
        xPlayer.Functions.AddMoney('bank', count)
    elseif (currency == "dirty") then
        local setting = Config.FrameworkSettings.dirtyMoney
        Inventory.AddItem(source, setting == "DEFAULT" and 'dirty_money' or setting, count)
    end
    TriggerClientEvent("pickle_policejob:updateMoney", source, money)
end

function RemoveMoney(source, count, currency)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    local currency = currency or "money"
    if (currency == "money") then
        xPlayer.Functions.RemoveMoney('cash', count)
    elseif (currency == "bank") then
        xPlayer.Functions.RemoveMoney('bank', count)
    elseif (currency == "dirty") then
        local setting = Config.FrameworkSettings.dirtyMoney
        Inventory.RemoveItem(source, setting == "DEFAULT" and 'dirty_money' or setting, count)
    end
    TriggerClientEvent("pickle_policejob:updateMoney", source, money)
end

function GetMoney(source, currency)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    local currency = currency or "money"
    local money = 0
    if (currency == "money") then
        money = xPlayer.PlayerData.money.cash
    elseif (currency == "bank") then
        money = xPlayer.PlayerData.money.bank
    elseif (currency == "dirty") then
        local setting = Config.FrameworkSettings.dirtyMoney
        money = Inventory.GetItemCount(source, setting == "DEFAULT" and 'dirty_money' or setting)
    end
    TriggerClientEvent("pickle_policejob:updateMoney", source, money)
    return money
end

function GetOwnedVehicleFromPlate(plate)
    local data = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate=@plate;", {
        ['@plate'] = plate,
    })[1]
    return data and {owner = data.citizenid} or nil
end

function AddOwnedVehicle(source, model)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
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
    MySQL.Async.fetchAll('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, plate, garage, state) VALUES (@license, @citizenid, @vehicle, @hash, @plate, @garage, @state)',
    {
        ['@license'] = xPlayer.PlayerData.license,
        ['@citizenid'] = xPlayer.PlayerData.citizenid,
        ['@vehicle'] = model,
        ['@hash'] = joaat(model),
        ['@plate'] = toupper(plate),
        ['@garage'] = "pillboxgarage",
        ['@state'] = 0
    })
end

function UpdateVehiclePlate(source, plate, newPlate)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    MySQL.Async.execute('UPDATE player_vehicles SET plate = @newPlate WHERE plate = @plate AND citizenid = @citizenid',
    {
        ['@newPlate'] = newPlate,
        ['@plate'] = plate,
        ['@citizenid'] = xPlayer.PlayerData.citizenid
    })
end

function ImpoundVehiclePlate(plate)
    MySQL.query("UPDATE player_vehicles SET state = 0 WHERE plate = ?", { plate })
end

function GetPlayerDateOfBirth(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return "Unknown" end
    return xPlayer.PlayerData.charinfo.dob
end

function GetPlayerGender(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return "Unknown" end
    return xPlayer.PlayerData.charinfo.gender == 0 and _L("male") or _L("female")
end

function GetPlayerJob(source)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return end
    return {name = xPlayer.PlayerData.job.name, label = xPlayer.PlayerData.job.label, rank_label = xPlayer.PlayerData.job.grade.name}
end

function SetPlayerJob(source, job, grade)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return end
    xPlayer.Functions.SetJob(job, grade)
    xPlayer.Functions.SetJobDuty(true)
end

function SetPlayerFrameworkDuty(source, onDuty)
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return end
    local jobName, jobGrade = GetPlayerDepartmentJob(source)
    if not jobName then return xPlayer.Functions.SetJobDuty(false) end
    xPlayer.Functions.SetJob(jobName, jobGrade)
    xPlayer.Functions.SetJobDuty(onDuty)
end

function IsPlayerAdmin(source)
    local source = tonumber(source)
    local permissions = QBCore.Functions.GetPermission(source)
    for i=1, #Config.AdminGroups do 
        if QBCore.Functions.HasPermission(source, Config.AdminGroups[i]) or IsPlayerAceAllowed(source, "command") then 
            return true 
        end
    end
    return false
end

function GetPlayerStatus(source)
    return {Alcohol = 0}
end

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local jobName, jobGrade = GetPlayerDepartmentJob(source)
    if not jobName then return end
    if IsPlayerOnDuty(source) and (job.name ~= jobName or not job.onduty) then
        SetPlayerDuty(false)
    elseif not IsPlayerOnDuty(source) and (job.name == jobName and not job.onduty) then
        SetPlayerDuty(true)
    end
end)

-- Evidence Status Support (For Breathalyzer)

RegisterNetEvent("evidence:server:UpdateStatus", function(status)
    local source = source
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
    if not xPlayer then return end
    local bac = 0.0
    if status.heavyalcohol then
        bac = 0.40 * ((status.heavyalcohol.time or 0) / 300)
    elseif status.alcohol then
        bac = 0.20 * ((status.alcohol.time or 0) / 300)
    end
    ExternalStatus.Alcohol[source] = math.floor(bac * 100) / 100 -- Format to 2 decimal places
end)

RegisterNetEvent("police:server:SeizeDriverLicense", function(targetId)
    local source = source
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetId))) > 3.0 then return end
    local xPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not xPlayer then return end
    local licenses = xPlayer.PlayerData.metadata['licences'] or {}
    local driverLicense = licenses['driver']
    if driverLicense then
        licenses['driver'] = false
        xPlayer.Functions.SetMetaData('licences', licenses)
        ShowNotification(targetId, _L("drivers_license_seized"))
    else
        ShowNotification(source, _L("target_no_driver_license"))
    end
end)

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.
    
    -- Search Player

    RegisterNetEvent("pickle_policejob:searchPlayer", function()
        local src = source
        local player, distance = QBCore.Functions.GetClosestPlayer(src)
        if player ~= -1 and distance < 2.5 then
            exports['qb-inventory']:OpenInventoryById(src, tonumber(player))
            ShowNotification(tonumber(player), _L("search_started"))
        else
            ShowNotification(src, _L("no_player_nearby"))
        end
    end)

    RegisterNetEvent("pickle_policejob:openStash", function(stash, isPersonalStash)
        local source = source
        local citizenId = GetIdentifier(source)
        exports['qb-inventory']:OpenInventory(source, stash .. (isPersonalStash and ("_" .. citizenId) or ""))
    end)

    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.CanCarryItem = function(source, name, count)
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        local weight = QBCore.Player.GetTotalWeight(xPlayer.PlayerData.items)
        local item = QBCore.Shared.Items[name:lower()]
        return ((weight + (item.weight * count)) <= QBCore.Config.Player.MaxWeight)
    end

    Inventory.GetInventory = function(source)
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        local items = {}
        local data = xPlayer.PlayerData.items
        for slot, item in pairs(data) do 
            items[#items + 1] = {
                name = item.name,
                label = item.label,
                count = item.amount,
                weight = item.weight,
                slot = slot,
                metadata = item.info or item.metadata
            }
        end
        return items
    end

    Inventory.UpdateInventory = function(source)
        SetTimeout(1000, function()
            TriggerClientEvent("pickle_policejob:updateInventory", source, Inventory.GetInventory(source))
        end)
    end

    Inventory.AddItem = function(source, name, count, metadata) -- Metadata is not required.
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        xPlayer.Functions.AddItem(name, count, nil, metadata)
        Inventory.UpdateInventory(source)
    end

    Inventory.RemoveItem = function(source, name, count)
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        xPlayer.Functions.RemoveItem(name, count)
        Inventory.UpdateInventory(source)
    end

    Inventory.AddWeapon = function(source, name, count, metadata) -- Metadata is not required.
        Inventory.AddItem(source, name, count, metadata)
    end

    Inventory.RemoveWeapon = function(source, name, count)
        Inventory.RemoveItem(source, name, count, metadata)
    end

    Inventory.GetItemCount = function(source, name)
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        if not xPlayer then return 0 end
        local item = xPlayer.Functions.GetItemByName(name)
        return item and item.amount or 0
    end

    Inventory.HasWeapon = function(source, name, count)
        return (Inventory.GetItemCount(source, name) > 0)
    end

    lib.callback.register("pickle_policejob:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)

    for item, data in pairs(QBCore.Shared.Items) do
        Inventory.Items[item] = {label = data.label}
    end
    Inventory.Ready = true
end)