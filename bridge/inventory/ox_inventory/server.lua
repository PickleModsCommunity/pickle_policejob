if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.CanCarryItem = function(source, name, count)
    return exports.ox_inventory:CanCarryItem(source, name, count)
end

Inventory.GetInventory = function(source)
    local items = {}
    local data = exports.ox_inventory:GetInventoryItems(source)
    for slot, item in pairs(data) do 
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            count = item.count,
            weight = item.weight,
            slot = item.slot,
            metadata = item.metadata or item.info
        }
    end
    return items
end

Inventory.AddItem = function(source, name, count, metadata) -- Metadata is not required.
    exports.ox_inventory:AddItem(source, name, count, metadata)
end

Inventory.RemoveItem = function(source, name, count, slot)
    exports.ox_inventory:RemoveItem(source, name, count, nil, slot)
end

Inventory.SetMetadata = function(source, slot, metadata)
    exports.ox_inventory:SetMetadata(source, slot, metadata)
end

Inventory.GetItemCount = function(source, name)
    local results = exports.ox_inventory:Search(source, "slots", name)
    if type(results) == "boolean" then
        return exports.ox_inventory:GetItemCount(source, name)
    end
    local count = 0
    for i=1, #results do
        count = count + results[i].count
    end
    return count
end

RegisterNetEvent("pickle_policejob:searchPlayer", function(targetId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    ShowNotification(targetId, _L("search_started"))
    ShowNotification(source, _L("search_started_police", GetPlayerCharacterName(targetId)))
end)

function InitializeInventory()
    Config.ImageDirectory = "nui://ox_inventory/web/images/"
    lib.callback.register("pickle_policejob:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    for item, data in pairs(exports.ox_inventory:Items()) do
        Inventory.Items[item] = {label = data.label}
    end

    exports.ox_inventory:RegisterStash("police_locker", "Police Locker", Config.Locker.slots, Config.Locker.maxWeight, true)

    
    Inventory.Ready = true
end