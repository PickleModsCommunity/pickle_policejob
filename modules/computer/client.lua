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

CreateThread(function()
    local lastVehicle = nil
    while true do
        if IsPlayerOnDuty() then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if DoesEntityExist(vehicle) then
                if not lastVehicle or lastVehicle ~= vehicle then
                    lastVehicle = vehicle
                    ShowNotification(_L("police_vehicle_entered", Config.Computer.vehicleCommand))
                end
            elseif lastVehicle then
                lastVehicle = nil
            end
        end
        Wait(1500)
    end
end)

RegisterCommand(Config.Computer.vehicleCommand, function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not DoesEntityExist(vehicle) then return ShowNotification(_L("not_in_vehicle")) end
    OpenComputer()
end)

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

RegisterNUICallback("openBailBounty", function(data, cb)
    cb("ok")
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "updateComputerInfo",
    })
    inComputer = false
    ExecuteCommand("bounties")
end)