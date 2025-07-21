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

function GetModelTemplates(model)
    local templates = json.decode(GetResourceKvpString("pickle_policejob:templates") or "{}") or {}
    return templates[tostring(model)] or {}
end

function SaveModelTemplates(model, newTemplates)
    local templates = json.decode(GetResourceKvpString("pickle_policejob:templates") or "{}") or {}
    templates[tostring(model)] = newTemplates
    SetResourceKvp("pickle_policejob:templates", json.encode(templates))
end

function GetVehicleExtras(vehicle)
    local model = GetEntityModel(vehicle)
    local extras = {}
    for i=0, 25 do
        if DoesExtraExist(vehicle, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    return extras
end

function GetVehicleColorData(vehicle, type)
    local r, g, b = 0, 0, 0
    if type == "primary" then
        r, g, b = GetVehicleCustomPrimaryColour(vehicle)
    elseif type == "secondary" then
        r, g, b = GetVehicleCustomSecondaryColour(vehicle)
    end
    local hex = string.format("#%02X%02X%02X", r, g, b)
    return hex
end

function SetVehicleColorData(vehicle, type, hex)
    local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
    if type == "primary" then
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
    elseif type == "secondary" then
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
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
    local entity = CreateVeh(vehicle.model, vehiclePreview.coords.x, vehiclePreview.coords.y, vehiclePreview.coords.z, vehiclePreview.rotation.z + offsetHeading, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetVehicleDirtLevel(entity, 0)
    SetVehicleEngineOn(entity, true, true, true)
    SetVehicleLights(entity, 2)
    SelectedVehicle = {
        model = vehicle.model,
        entity = entity,
        extras = GetVehicleExtras(entity),
        templates = GetModelTemplates(vehicle.model),
        colors = {
            primary = GetVehicleColorData(entity, "primary"),
            secondary = GetVehicleColorData(entity, "secondary"),
        },
        coords = vehiclePreview.coords,
        rotation = vehiclePreview.rotation + vector3(0.0, 0.0, offsetHeading),
        livery = 1,
    }
    SetVehicleSiren(SelectedVehicle.entity, true)
    SetVehicleHasMutedSirens(SelectedVehicle.entity, true)
    SetVehicleLivery(SelectedVehicle.entity, SelectedVehicle.livery - 1)
    SendNUIMessage({
        type = "selectVehicle",
        vehicleInfo = {
            index = index - 1,
            currentTemplate = nil,
            liveryCount = GetVehicleLiveryCount(entity),
            livery = SelectedVehicle.livery,
            extras = SelectedVehicle.extras,
            colors = SelectedVehicle.colors,
            templates = SelectedVehicle.templates,
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

RegisterNUICallback("changeLivery", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    local nextIndex = SelectedVehicle.livery + (data.left and -1 or 1)
    local liveryCount = GetVehicleLiveryCount(SelectedVehicle.entity)
    if nextIndex < 1 then
        nextIndex = liveryCount > 0 and liveryCount or 1
    elseif liveryCount <= 1 or nextIndex > liveryCount then
        nextIndex = 1
    end
    SelectedVehicle.livery = nextIndex
    SetVehicleLivery(SelectedVehicle.entity, SelectedVehicle.livery - 1)
    SendNUIMessage({
        type = "updateSelectedVehicle",
        vehicleInfo = {
            livery = SelectedVehicle.livery,
        },
    })
end)

RegisterNUICallback("toggleExtra", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    local index = tostring(tonumber(data.index))
    SelectedVehicle.extras[index] = not data.state
    SetVehicleExtra(SelectedVehicle.entity, tonumber(index), SelectedVehicle.extras[index] and 0 or 1)
    SendNUIMessage({
        type = "updateSelectedVehicle",
        vehicleInfo = {
            extras = SelectedVehicle.extras,
        },
    })
end)

RegisterNUICallback("changeColor", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    SelectedVehicle.colors[data.color] = data.value
    SetVehicleColorData(SelectedVehicle.entity, data.color, data.value)
    SendNUIMessage({
        type = "updateSelectedVehicle",
        vehicleInfo = {
            colors = SelectedVehicle.colors,
        },
    })
end)    

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

RegisterNUICallback("takeVehicle", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("selectTemplate", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    local templates = GetModelTemplates(SelectedVehicle.model)
    if not templates[data.name] then return ShowNotification(_L("garage_template_not_found", data.name)) end
    SelectedVehicle.livery = templates[data.name].livery
    SelectedVehicle.extras = templates[data.name].extras
    SelectedVehicle.colors = templates[data.name].colors
    SetVehicleLivery(SelectedVehicle.entity, SelectedVehicle.livery - 1)
    for i=0, 25 do
        if SelectedVehicle.extras[tostring(i)] ~= nil then
            SetVehicleExtra(SelectedVehicle.entity, i, SelectedVehicle.extras[tostring(i)] and 0 or 1)
        end
    end
    SetVehicleColorData(SelectedVehicle.entity, "primary", SelectedVehicle.colors.primary)
    SetVehicleColorData(SelectedVehicle.entity, "secondary", SelectedVehicle.colors.secondary)
    SendNUIMessage({
        type = "updateSelectedVehicle", 
        vehicleInfo = {
            currentTemplate = data.name,
            livery = SelectedVehicle.livery,
            extras = SelectedVehicle.extras,
            colors = SelectedVehicle.colors,
        },
    })
end)

RegisterNUICallback("saveTemplate", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    local templates = GetModelTemplates(SelectedVehicle.model)
    templates[data.name] = {
        livery = data.template.livery,
        extras = data.template.extras,
        colors = data.template.colors,
    }
    SaveModelTemplates(SelectedVehicle.model, templates)
    ShowNotification(_L("garage_template_saved", data.name))
    SendNUIMessage({
        type = "updateSelectedVehicle",
        vehicleInfo = {
            currentTemplate = data.name,
            templates = templates,
        },
    })
end)

RegisterNUICallback("deleteTemplate", function(data, cb)
    cb("ok")
    if not SelectedVehicle then return end
    local templates = GetModelTemplates(SelectedVehicle.model)
    templates[data.name] = nil
    SaveModelTemplates(SelectedVehicle.model, templates)
    ShowNotification(_L("garage_template_deleted", data.name))
    SendNUIMessage({
        type = "updateSelectedVehicle",
        vehicleInfo = {
            currentTemplate = "none",
            templates = templates,
        },
    })
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        CloseGarage()
    end
end)