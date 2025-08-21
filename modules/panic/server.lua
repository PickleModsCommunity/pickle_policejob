local Alerts = {}

RegisterNetEvent("pickle_policetools:panic:startAlert", function()
    local source = source
   
    if Alerts[source] then 
        return ShowNotification(source, _L("panic_in_progress"))
    end

    if not IsPlayerOnDuty(source) then 
        return ShowNotification(source, _L("panic_denied"))
    end

    if Config.Panic.RequiredItem and Inventory.GetItemCount(source, Config.Panic.RequiredItem) < 1 then 
        return ShowNotification(source, _L("panic_missing"))
    end
    
    Alerts[source] = {
        coords = GetEntityCoords(GetPlayerPed(source))
    }
    
    TriggerClientEvent("pickle_policetools:panic:newAlert", -1, source, Alerts[source])

    SetTimeout(1000 * Config.Panic.AlertLength, function()
        Alerts[source] = nil
        TriggerClientEvent("pickle_policetools:panic:removeAlert", -1, source)    
    end)
end)

if Config.Panic.RequiredItem then 
    RegisterUsableItem(Config.Panic.RequiredItem, function(source) 
        if not IsPlayerOnDuty(source) then 
            return ShowNotification(source, _L("panic_denied"))
        end
        
        TriggerClientEvent("pickle_policetools:panic:attemptPanicButton", source)
    end)
end