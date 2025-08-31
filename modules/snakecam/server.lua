local HeldItems = {}

RegisterCommand("snakecam", function(source)
    local source = source

    if not IsPlayerOnDuty(source) then 
        return ShowNotification(source, _L("snake_denied"))
    end

    if Config.Snakecam.RequiredItem and Inventory.GetItemCount(source, Config.Snakecam.RequiredItem) < 1 then 
        return ShowNotification(source, _L("snake_missing"))
    elseif Config.Snakecam.RequiredItem then
        HeldItems[source] = true
        Inventory.RemoveItem(source, Config.Snakecam.RequiredItem, 1)
    end

    TriggerClientEvent("pickle_policejob:tools:snakecam:attemptSnakecam", source)
end)

RegisterNetEvent("pickle_policejob:tools:snakecam:requestRefund", function()
    local source = source
    if HeldItems[source] then 
        HeldItems[source] = nil
        if Config.Snakecam.RequiredItem then
            Inventory.AddItem(source, Config.Snakecam.RequiredItem, 1)
        end
    end
end)


if Config.Snakecam.RequiredItem then 
    RegisterUsableItem(Config.Snakecam.RequiredItem, function(source) 
        HeldItems[source] = true
        Inventory.RemoveItem(source, Config.Snakecam.RequiredItem, 1)
        TriggerClientEvent("pickle_policejob:tools:snakecam:attemptSnakecam", source)
    end)
end