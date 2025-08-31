if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.OpenStash = function(stash, isPersonalStash)
    exports.ox_inventory:openInventory('stash', stash)
end

RegisterNetEvent("pickle_policejob:setupInventory", function(items)
    Inventory.Items = items
    Inventory.Ready = true
end)

function InitializeInventory()
    Config.ImageDirectory = "nui://ox_inventory/web/images/"
    OpenNearbyInventory = function()
        Config.Integrations.inventory.OpenNearbyInventory()
        return exports.ox_inventory:openNearbyInventory()
    end
end