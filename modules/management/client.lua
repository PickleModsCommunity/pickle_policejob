RegisterNetEvent("pickle_policejob:openManagement", function(data)
    print(json.encode(data.departments, {indent = true}))
    SendNUIMessage({
        type = "openManagementEditor",
        departments = data.departments,
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent("pickle_policejob:updateManagement", function(data)
    if data.type == "updateMembers" then
        print(json.encode(data, {indent = true}))
        SendNUIMessage({
            type = "updateManagementMembers",
            departmentId = data.departmentId,
            members = data.members,
        })
    elseif data.type == "createDepartment" then
        SendNUIMessage({
            type = "createManagementDepartment",
            department = data.department,
        })
    end
end)

RegisterNUICallback("closeManagement", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("managementAction", function(data, cb)
    TriggerServerEvent("pickle_policejob:managementAction", data.action, data.data)
    cb("ok")
end)