RegisterNetEvent("pickle_policetools:eas:attemptAlert", function() 
    local input = lib.inputDialog('Emergency Alert System', {
        {type = "input", label = 'Alert Message', placeholder = "Type your message here."},
    })

    if not (not input or input[1] == "") then 
        TriggerServerEvent("pickle_policetools:eas:sendAlert", input[1])
    end
end)


RegisterNetEvent("pickle_policetools:eas:receiveAlert", function(text) 
    SendNUIMessage({
        displayEAS = true,
        data = {
            text = text
        }
    })
end)