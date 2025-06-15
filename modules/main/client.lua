local LocalDepartments = {}
local CurrentDepartment = nil

function OpenFrontdeskOffdutyPrompt(id, entityId)
    local input = lib.inputDialog(_L("offduty_prompt_title"), {
        {type = 'textarea', label = _L("offduty_prompt_label"), placeholder = _L("offduty_prompt_placeholder")},
    })
    if not input then 
        OpenFrontdesk(id, entityId)
        return 
    end
    TriggerServerEvent("pickle_policejob:toggleDuty", id, entityId, input[1])
end

function OpenFrontdeskDutyLogs(id, entityId, data)
    local menuId = "pickle_policejob:frontdesk:duty_logs"
    local options = {}
    for i=1, #data.memberData.recentDutyLogs do
        options[#options+1] = {
            title = _L("duty_log_title", GetFormattedDate(data.memberData.recentDutyLogs[i].finish - data.memberData.recentDutyLogs[i].duration, data.date), GetFormattedDate(data.memberData.recentDutyLogs[i].finish, data.date)),
            description = _L("duty_log_description", GetFormattedTime(data.memberData.recentDutyLogs[i].duration)),
            icon = "clipboard-list",
        }
    end
    lib.registerContext({
        id = menuId,
        title = _L("view_duty_logs"),
        options = options
    })
    lib.showContext(menuId)
end

function OpenFrontdesk(id, entityId)
    if OPENING_MENU then return end
    OPENING_MENU = true
    ServerCallback("pickle_policejob:openFrontdesk", function(data)
        OPENING_MENU = false
        if not data then return end
        local options = {}
        local menuId = "pickle_policejob:frontdesk"
        if data.departmentId and id == data.departmentId then
            options[#options+1] = {
                title = _L(data.memberData.onDuty and "toggle_offduty" or "toggle_onduty"),
                description = data.memberData.onDuty and _L("toggle_offduty_description", GetFormattedTime(data.time - data.memberData.onDuty)) or _L("toggle_onduty_description"),
                icon = data.memberData.onDuty and "stop" or "play",
                onSelect = function()
                    if data.memberData.onDuty then
                        OpenFrontdeskOffdutyPrompt(id, entityId)
                    else
                        TriggerServerEvent("pickle_policejob:toggleDuty", id, entityId)
                    end
                end,
            }
            options[#options+1] = {
                title = _L("view_duty_logs"),
                description = _L("view_duty_logs_description"),
                icon = "clipboard-list",
                onSelect = function()
                    OpenFrontdeskDutyLogs(id, entityId, data)
                end,
            }
        end
        if #options == 0 then
            return ShowNotification("ERR_NO_OPTIONS")
        end
        lib.registerContext({
            id = menuId,
            title = _L("interact_frontdesk"),
            options = options
        })
        lib.showContext(menuId)
    end, id, entityId)
end

function EnsureDepartment(id)
    if LocalDepartments[id] then return end
    local localDepartment = {
        entities = {},
    }
    for i=1, #Config.Departments[id].entities do
        local entity = Config.Departments[id].entities[i]
        if entity.type == "frontdesk" then
            localDepartment.entities[#localDepartment.entities+1] = {
                id = entity.id,
                interact = CreateInteraction({
                    label = _L("interact_frontdesk"),
                    icon = Config.TargetIcons["frontdesk"],
                    coords = entity.location.coords + vector3(0.0, 0.0, 1.0),
                    heading = entity.location.heading,
                    model = entity.ped and { modelType = "ped", hash = GetHashKey(entity.ped) } or nil,
                }, function()
                    OpenFrontdesk(id, entity.id)
                end)
            }
        end
    end
end

RegisterNetEvent("pickle_policejob:initializeDepartment", function(id, department)
    if type(id) == "table" then
        Departments = id
        for k, v in pairs(Departments) do
            EnsureDepartment(k)
        end
    else
        Departments[id] = department
        EnsureDepartment(id)
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent("pickle_policejob:initializePlayer")
    end
end)