local inGarage = false
local SelectedVehicle = nil
local GarageInfo = nil
local CurrentCamera = nil

function EnsureGarageCamera()
    if not CurrentCamera then
        local initialCamSettings = {
            coords = GetGameplayCamCoord(),
            rotation = GetGameplayCamRot(),
            fov = GetGameplayCamFov(),
        }
        CurrentCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
            initialCamSettings.coords.x, initialCamSettings.coords.y, initialCamSettings.coords.z, 
            initialCamSettings.rotation.x, initialCamSettings.rotation.y, initialCamSettings.rotation.z, initialCamSettings.fov
        )
        SetCamActive(CurrentCamera, true)
        RenderScriptCams(true, false, 0, true, true)
    end
end

function ExitGarageCamera()
    if CurrentCamera then
        ClearFocus()
        DestroyAllCams()
        RenderScriptCams(false, true, 2000, true, false)
        CurrentCamera = nil
    end
end

function SelectGarageVehicle(index)
    if not GarageInfo or not GarageInfo.vehicles[index] then return end
    if SelectedVehicle then
        DeleteEntity(SelectedVehicle.entity)
        SelectedVehicle = nil
    end
    local department = Departments[GarageInfo.departmentId]
    if not department then return ShowNotification(_L("no_department")) end
    local location = GetDepartmentLocation(department.id, GarageInfo.locationId)
    if not location then return ShowNotification(_L("no_location")) end
    local vehicle = GarageInfo.vehicles[index]
    local vehiclePreview = location.positions.vehicle_preview
    local offsetHeading = 140.0
    SelectedVehicle = {
        entity = CreateVeh(vehicle.model, vehiclePreview.coords.x, vehiclePreview.coords.y, vehiclePreview.coords.z, vehiclePreview.rotation.z + offsetHeading, false, false),
        coords = vehiclePreview.coords,
        rotation = vehiclePreview.rotation + vector3(0.0, 0.0, offsetHeading),
    }
    SetVehicleSiren(SelectedVehicle.entity, true)
    SetVehicleHasMutedSirens(SelectedVehicle.entity, true)
    SendNUIMessage({
        type = "selectVehicle",
        vehicleInfo = {
            index = index - 1,
            currentTemplate = nil,
            liveryCount = 12,
            livery = 1,
            extras = {
                [0] = false,
                [1] = false,
                [2] = false,
                [3] = false,
                [4] = false,
                [5] = false,
                [6] = false,
            },
            colors = {
                primary = 0,
                secondary = 0,
            },
            templates = {},
        },
    })
end

function RotateVehicle(distance, speed)
    if not SelectedVehicle then return end
    local heading = GetEntityHeading(SelectedVehicle.entity) + (((distance * speed) / 100) * 2)
    SetEntityHeading(SelectedVehicle.entity, heading)
end

function OpenVehicleSpawn(departmentId, locationId)
    if inGarage then return end
    inGarage = true
    local department = Departments[departmentId]
    if not department then return ShowNotification(_L("no_department")) end
    local location = GetDepartmentLocation(departmentId, locationId)
    if not location then return ShowNotification(_L("no_location")) end
    ServerCallback("pickle_policejob:openGarage", function(result, err)
        if not result then
            inGarage = false
            return ShowNotification(err)
        end
        GarageInfo = {
            departmentId = departmentId,
            locationId = locationId,
            vehicles = result,
        }
        inGarage = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "updateGarageInfo",
            garageInfo = {
                vehicles = GarageInfo.vehicles,
            },
        })
        local vehiclePreview = location.positions.vehicle_preview
        local offsetObj = CreateProp(`prop_tennis_ball`, vehiclePreview.coords.x, vehiclePreview.coords.y, vehiclePreview.coords.z, false, false, false)
        FreezeEntityPosition(offsetObj, true)
        SetEntityHeading(offsetObj, vehiclePreview.rotation.z)
        local camCoords = GetOffsetFromEntityInWorldCoords(offsetObj, 0.0, -4.0, 1.25)
        DeleteEntity(offsetObj)
        SetFocusArea(camCoords)
        EnsureGarageCamera()
        SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
            -20.0, 0.0, vehiclePreview.rotation.z, 90.0, 
            2000, 0, 0, 2
        )
        SetTimeout(10, function()
            SelectGarageVehicle(1)
        end)
    end)
end

function CloseGarage()
    inGarage = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "updateGarageInfo",
    })
    ExitGarageCamera()
    if SelectedVehicle then
        DeleteEntity(SelectedVehicle.entity)
        SelectedVehicle = nil
    end
end

RegisterNUICallback("closeGarage", function(data, cb)
    cb("ok")
    CloseGarage()
end)

RegisterNUICallback("rotateMouse", function(data, cb)
    cb("ok")
    RotateVehicle(data.distance, data.speed)
end)

RegisterNUICallback("selectVehicle", function(data, cb)
    cb("ok")
    SelectGarageVehicle(data.index + 1)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        CloseGarage()
    end
end)