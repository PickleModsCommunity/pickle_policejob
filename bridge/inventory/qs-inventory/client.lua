if GetResourceState('qs-inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

Inventory.OpenStash = function(stash, isPersonalStash)
    local other = {}
    other.maxweight = Config.Locker.maxWeight
    other.slots = Config.Locker.slots
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stash, other)
    TriggerEvent("inventory:client:SetCurrentStash", stash)
end

RegisterNetEvent("pickle_policejob:setupInventory", function(items)
    Inventory.Items = items
    Inventory.Ready = true
end)


function InitializeInventory()
    Config.ImageDirectory = "nui://qs-inventory/html/images/"
    OpenNearbyInventory = function()
        local closestPlayer = GetClosestPlayer()
        if not closestPlayer then return ShowNotification(_L("no_player_nearby")) end
        TriggerServerEvent("pickle_policejob:searchPlayer", GetPlayerServerId(closestPlayer))
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", GetPlayerServerId(closestPlayer))
        Config.Integrations.inventory.OpenNearbyInventory()
    end
end