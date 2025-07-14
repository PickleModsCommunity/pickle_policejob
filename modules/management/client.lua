local inManagement = false

function SetEditorFocus(toggle)
    SetNuiFocus(toggle, toggle)
    SendNUIMessage({
        type = "setManagementFocus",
        toggle = toggle,
    })
end

RegisterNetEvent("pickle_policejob:openManagement", function(data)
    inManagement = true
    SendNUIMessage({
        type = "openManagementEditor",
        departments = data.departments,
    })
    SetEditorFocus(true)
    CreateThread(function()
        while inManagement do
            Wait(0)
            if IsControlJustPressed(0, 47) then
                SetEditorFocus(true)
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
    SetEditorFocus(false)
    cb("ok")
end)

RegisterNUICallback("exitManagementEditor", function(data, cb)
    inManagement = false
    SendNUIMessage({
        type = "closeManagementEditor",
    })
    SetEditorFocus(false)
    cb("ok")
end)

RegisterNUICallback("managementAction", function(data, cb)
    TriggerServerEvent("pickle_policejob:managementAction", data.action, data.data)
    cb("ok")
end)