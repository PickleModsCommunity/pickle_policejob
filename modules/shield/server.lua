local HeldShields = {}

RegisterCommand("shield", function(source)
    local source = source

    if not IsPlayerOnDuty(source) then 
        return ShowNotification(source, _L("shield_denied"))
    end

    if Config.Shields.RequiredItem and Inventory.GetItemCount(source, Config.Shields.RequiredItem) < 1 then 
        return ShowNotification(source, _L("shield_missing"))
    elseif Config.Shields.RequiredItem then
        HeldShields[source] = true
        Inventory.RemoveItem(source, Config.Shields.RequiredItem, 1)
    end

    TriggerClientEvent("pickle_policejob:tools:shields:openShield", source)
end)

RegisterNetEvent("pickle_policejob:tools:shields:requestRefund", function()
    local source = source
    if HeldShields[source] then 
        HeldShields[source] = nil
        if Config.Shields.RequiredItem then
            Inventory.AddItem(source, Config.Shields.RequiredItem, 1)
        end
    end
end)

if Config.Shields.RequiredItem then 
    RegisterUsableItem(Config.Shields.RequiredItem, function(source) 
        Inventory.RemoveItem(source, Config.Shields.RequiredItem, 1)
        HeldShields[source] = true
        TriggerClientEvent("pickle_policejob:tools:shields:openShield", source)
    end)
end