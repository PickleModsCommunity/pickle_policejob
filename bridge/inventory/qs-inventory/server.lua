if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.CanCarryItem = function(source, name, count)
    return exports['qs-inventory']:CanCarryItem(source, name, count)
end

Inventory.GetInventory = function(source)
    local items = {}
    local data = exports['qs-inventory']:GetInventory(source)
    for slot, item in pairs(data) do 
        items[#items + 1] = {
            name = item.name,
            label = item.label,
            count = item.amount,
            weight = item.weight,
            slot = item.slot,
            metadata = item.info or item.metadata
        }
    end
    return items
end

Inventory.AddItem = function(source, name, count, metadata) -- Metadata is not required.
    exports['qs-inventory']:AddItem(source, name, count, nil, metadata)
end

Inventory.RemoveItem = function(source, name, count, slot)
    exports['qs-inventory']:RemoveItem(source, name, count, slot)
end

Inventory.SetMetadata = function(source, slot, metadata)
    exports['qs-inventory']:SetItemMetadata(source, slot, metadata)
end

Inventory.GetItemCount = function(source, name)
    return exports['qs-inventory']:GetItemTotalAmount(source, name) or 0
end

RegisterNetEvent("pickle_policejob:searchPlayer", function(targetId)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    ShowNotification(targetId, _L("search_started"))
    ShowNotification(source, _L("search_started_police", GetPlayerCharacterName(targetId)))
end)

function InitializeInventory()
    Config.ImageDirectory = "nui://qs-inventory/html/images/"
    lib.callback.register("pickle_policejob:getInventory", function(source)
        return Inventory.GetInventory(source)
    end)
    
    for item, data in pairs(exports['qs-inventory']:GetItemList()) do
        Inventory.Items[item] = {label = data.label}
    end
    
    Inventory.Ready = true
end