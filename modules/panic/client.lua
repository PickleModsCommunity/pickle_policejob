Alerts = {}

function StartPanicAlert()
    if not IsPlayerOnDuty() then 
        return 
    end

    TriggerServerEvent("pickle_policetools:panic:startAlert")
end

RegisterNetEvent("pickle_policetools:panic:newAlert", function(source, data)
    if not IsPlayerOnDuty() then 
        return 
    end
    
    ShowNotification(_L("panic_new"))

    Alerts[source] = data
    Alerts[source].blips = {}
    
    for i=1, #Config.Panic.Blips do 
        local blipCFG = Config.Panic.Blips[i]
        local blip = {
            Location = data.coords,
            ID = blipCFG.ID,
            Display = blipCFG.Display,
            Scale = blipCFG.Scale,
            Color = blipCFG.Color,
            Label = blipCFG.Label
        }

        Alerts[source].blips[i] = CreateBlip(blip)
    end
end)

RegisterNetEvent("pickle_policetools:panic:removeAlert", function(source)
    if Alerts[source] then 
        for i=1, #Alerts[source].blips do 
            RemoveBlip(Alerts[source].blips[i])
        end
        Alerts[source] = nil
    end
end)

RegisterNetEvent("pickle_policetools:panic:attemptPanicButton", function()
    StartPanicAlert()
end)

RegisterCommand("panic", function()
    StartPanicAlert()
end)