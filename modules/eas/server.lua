RegisterNetEvent("pickle_policetools:eas:sendAlert", function(msg)
    if not IsPlayerOnDuty(source) then 
        return ShowNotification(source, _L("eas_denied"))
    end

    if Config.EAS.RequiredItem and Inventory.GetItemCount(source, Config.EAS.RequiredItem) < 1 then 
        return ShowNotification(source, _L("eas_missing"))
    end

    TriggerClientEvent("pickle_policetools:eas:receiveAlert", -1, msg)
end)

RegisterCommand("eas", function(source) 
    if not IsPlayerOnDuty(source) then 
        return ShowNotification(source, _L("eas_denied"))
    end

    if Config.EAS.RequiredItem and Inventory.GetItemCount(source, Config.EAS.RequiredItem) < 1 then 
        return ShowNotification(source, _L("eas_missing"))
    end
    
    TriggerClientEvent("pickle_policetools:eas:attemptAlert", source)
end)

if Config.EAS.RequiredItem then 
    RegisterUsableItem(Config.EAS.RequiredItem, function(source) 
        if not IsPlayerOnDuty(source) then 
            return ShowNotification(source, _L("eas_denied"))
        end

        TriggerClientEvent("pickle_policetools:eas:attemptAlert", source)
    end)
end