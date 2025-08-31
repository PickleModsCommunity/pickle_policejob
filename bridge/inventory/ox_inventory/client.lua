if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

RegisterNetEvent("pickle_policejob:setupInventory", function(items)
    Inventory.Items = items
    Inventory.Ready = true
end)

function InitializeInventory()
    OpenNearbyInventory = function()
        Config.Integrations.inventory.OpenNearbyInventory()
        return exports.ox_inventory:openNearbyInventory()
    end
end