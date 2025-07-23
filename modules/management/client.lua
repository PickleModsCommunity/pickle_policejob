local inManagement = false
local temporaryEntity = nil
local hoveredLocation = nil

LOCATION_TYPES = {
    ["front_desk"] = {
        locations = {},
        settings = {"ped"},
    },
    ["garage"] = {
        locations = {"vehicle_preview", "vehicle_spawn"},
        settings = {"ped", "garageType"},
    },
    ["armory"] = {
        locations = {},
        settings = {"ped"},
    },
    ["computer"] = {
        locations = {},
        settings = {},
    },
}

function SetManagementFocus(toggle)
    SetNuiFocus(toggle, toggle)
    SendNUIMessage({
        type = "setManagementFocus",
        toggle = toggle,
    })
end

function GetDirectionFromRotation(rotation)
    local dm = (math.pi / 180)
    return vector3(-math.sin(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.cos(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.sin(dm * rotation.x))
end

function GetDirectionCoords()
    local range = 1000.0
	local coords = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
	local ecoords = vector3(coords.x + dir.x * range, coords.y + dir.y * range, coords.z + dir.z * range)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, ecoords.x, ecoords.y, ecoords.z, -1, PlayerPedId(), 1))
	return hit, endCoords, entityHit 
end

function DeleteTemporaryEntity()
    if temporaryEntity then
        DeleteEntity(temporaryEntity.entity)
        temporaryEntity = nil
    end
end

function SetTemporaryEntity(data)
    DeleteTemporaryEntity()
    local entity = nil
    if (data.type == "ped") then
        entity = CreateNPC(data.model, data.coords.x, data.coords.y, data.coords.z, data.rotation.z, false, false)
    elseif (data.type == "object") then
        entity = CreateProp(data.model, data.coords.x, data.coords.y, data.coords.z, false, false, false)
    end
    SetEntityCoords(entity, data.coords.x, data.coords.y, data.coords.z, false, false, false, false)
    SetEntityRotation(entity, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)
    temporaryEntity = {
        entity = entity,
        data = data,
    }
    return temporaryEntity
end

function GetDepartmentLocation(departmentId, locationId)
    local department = Departments[departmentId]
    if not department then return end
    for i=1, #department.locations do
        if department.locations[i].id == locationId then
            return department.locations[i], i
        end
    end
    return nil
end

RegisterNetEvent("pickle_policejob:openManagement", function(data)
    inManagement = true
    SendNUIMessage({
        type = "openManagementEditor",
        departments = data.departments,
    })
    SetManagementFocus(true)
    CreateThread(function()
        while inManagement do
            Wait(0)
            if IsControlJustPressed(0, 47) and not inGizmo then
                SetManagementFocus(true)
            end
        end
    end)
end)

RegisterNetEvent("pickle_policejob:updateManagement", function(data)
    SendNUIMessage({
        type = "updateManagement",
        data = data,
    })
    -- if data.type == "updateMembers" then
    --     print(json.encode(data, {indent = true}))
    --     SendNUIMessage({
    --         type = "updateManagementMembers",
    --         departmentId = data.departmentId,
    --         members = data.members,
    --     })
    -- elseif data.type == "createDepartment" then
    --     SendNUIMessage({
    --         type = "createManagementDepartment",
    --         department = data.department,
    --     })
    -- end
end)

RegisterNUICallback("disableManagementFocus", function(data, cb)
    SetManagementFocus(false)
    cb("ok")
end)

RegisterNUICallback("exitManagementEditor", function(data, cb)
    inManagement = false
    DeleteTemporaryEntity()
    SendNUIMessage({
        type = "closeManagementEditor",
    })
    SetManagementFocus(false)
    cb("ok")
end)

RegisterNUICallback("managementAction", function(data, cb)
    print(json.encode(data, {indent = true}))
    TriggerServerEvent("pickle_policejob:managementAction", data.action, data.data)
    cb("ok")
end)

RegisterNUICallback("editLocation", function(data, cb)
    print(json.encode(data, {indent = true}))
    cb("ok")
    SendNUIMessage({
        type = "setManagementHidden",
        hidden = true,
    })
    SetManagementFocus(false)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local coords = (data.coords and #(vector3(data.coords.x, data.coords.y, data.coords.z) - playerCoords) < 100.0) and data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = (#(vector3(data.rotation.x, data.rotation.y, data.rotation.z) - vector3(0.0, 0.0, 0.0)) > 1.0 and vector3(data.rotation.x, data.rotation.y, data.rotation.z) or vector3(0.0, 0.0, GetEntityHeading(ped)))
    if not data.info.departmentId then
        if data.id == "point" and data.info.settings.ped and data.info.settings.ped ~= "" then
            SetTemporaryEntity({type = "ped", model = GetHashKey(data.info.settings.ped), coords = coords, rotation = rotation})
        else
            SetTemporaryEntity({type = "object", model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        end
        local result = StartGizmoEditor({entity = temporaryEntity.entity, coords = coords, rotation = rotation})
        SendNUIMessage({
            type = "setLocation",
            id = data.id,
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
    else
        UnrenderDepartmentLocation(data.info.departmentId, data.info.locationId)
        if data.id == "point" and data.info.settings.ped and data.info.settings.ped ~= "" then
            SetTemporaryEntity({type = "ped", model = GetHashKey(data.info.settings.ped), coords = coords, rotation = rotation})
        else
            SetTemporaryEntity({type = "object", model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        end
        local result = StartGizmoEditor({entity = temporaryEntity.entity, coords = coords, rotation = rotation})
        DeleteTemporaryEntity()
        TriggerServerEvent("pickle_policejob:managementAction", "updateLocation", {
            pointId = data.id,
            departmentId = data.info.departmentId,
            locationId = data.info.locationId,
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
        SendNUIMessage({
            type = "setLocation",
            id = data.id,
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
    end
    SetManagementFocus(true)
    SendNUIMessage({
        type = "setManagementHidden",
        hidden = false,
    })
end)

RegisterNUICallback("getNearbyPlayers", function(data, cb)
    ServerCallback("pickle_policejob:getNearbyPlayers", function(result)
        cb(result)
    end)
end)

RegisterNUICallback("setCurrentLocation", function(data, cb)
    cb("ok")
    if inGizmo then return end
    if not data.location then
        print("deleting temporary entity", json.encode(data, {indent = true}))
        DeleteTemporaryEntity()
    elseif temporaryEntity then
        local coords = data.location.positions.point.coords
        local rotation = data.location.positions.point.rotation
        if data.location.settings.ped and data.location.settings.ped ~= "" then
            SetTemporaryEntity({type = "ped", model = GetHashKey(data.location.settings.ped), coords = coords, rotation = rotation})
        else
            SetTemporaryEntity({type = "object", model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        end
    end
end)

RegisterNUICallback("setHoveredLocation", function(data, cb)
    cb("ok")
    if hoveredLocation == data.locationId then return end
    hoveredLocation = data.locationId
    if not hoveredLocation then return end
    CreateThread(function()
        local location = GetDepartmentLocation(data.departmentId, hoveredLocation)
        if not location then return end
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        while inManagement and hoveredLocation and not inGizmo and hoveredLocation == data.locationId do
            DrawMarker(0, coords.x, coords.y, coords.z + ((location.settings.ped and location.settings.ped ~= "") and 2.05 or 0.25), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 255, 255, 255, 255)
            Wait(0)
        end
    end)
end)