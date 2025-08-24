local inComputer = false

function OpenComputer(id, locationId)
    if inComputer then return end
    inComputer = true
    lib.callback("pickle_policejob:openComputer", false, function(result, err)
        if not result then 
            inComputer = false
            return ShowNotification(err)
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "updateComputerInfo",
            computerInfo = result,
        })
    end)
end

RegisterNetEvent("pickle_policejob:updateComputerDepartment", function(data)
    SendNUIMessage({
        type = "updateComputerDepartment",
        data = data,
    })
end)

RegisterNUICallback("updateComputerDepartment", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_policejob:updateComputerDepartment", data.type, data)
end)

RegisterNUICallback("closeComputer", function(data, cb)
    cb("ok")
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "updateComputerInfo",
    })
    inComputer = false
    TriggerServerEvent("pickle_policejob:closeComputer")
end)