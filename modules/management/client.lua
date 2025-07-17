local inManagement = false

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
    SendNUIMessage({
        type = "closeManagementEditor",
    })
    SetManagementFocus(false)
    cb("ok")
end)

RegisterNUICallback("managementAction", function(data, cb)
    TriggerServerEvent("pickle_policejob:managementAction", data.action, data.data)
    cb("ok")
end)

RegisterNUICallback("editLocation", function(data, cb)
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
    if not data.info then
        local result = StartGizmoEditor({model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        SendNUIMessage({
            type = "setLocation",
            id = data.id,
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
    else
        local result = StartGizmoEditor({model = `prop_tennis_ball`, coords = coords, rotation = rotation})
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