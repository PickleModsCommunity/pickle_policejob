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

function OpenFrontdeskDutyLogEntry(id, entityId, data, index)
    local log = data.memberData.recentDutyLogs[index]
    if not log then return ShowNotification("ERR_NO_LOG") end
    local input = lib.inputDialog(_L("duty_log_entry_title"), {
        {type = "input", label = _L("duty_log_entry_starttimestamp"), default = log.startTimestamp, disabled = true},
        {type = "input", label = _L("duty_log_entry_finishtimestamp"), default = log.finishTimestamp, disabled = true},
        {type = "input", label = _L("duty_log_entry_duration"), default = GetFormattedTime(log.duration), disabled = true},
        {type = "textarea", label = _L("duty_log_entry_report"), default = log.report or _L("duty_log_entry_report_placeholder"), disabled = true},
    })
    OpenFrontdeskDutyLogs(id, entityId, data)
    return 
end

function OpenFrontdeskDutyLogs(id, entityId, data)
    local menuId = "pickle_policejob:frontdesk:duty_logs"
    local options = {}
    for i=1, #data.memberData.recentDutyLogs do
        options[#options+1] = {
            title = data.memberData.recentDutyLogs[i].startTimestamp,
            description = _L("duty_log_description", GetFormattedTime(data.memberData.recentDutyLogs[i].duration)),
            icon = "clipboard-list",
            onSelect = function()
                OpenFrontdeskDutyLogEntry(id, entityId, data, i)
            end,
        }
    end
    if #options == 0 then
        options[#options+1] = {
            title = _L("duty_log_no_logs"),
            disabled = true,
        }
    end
    lib.registerContext({
        id = menuId,
        title = _L("view_duty_logs"),
        options = options,
        onExit = function()
            OpenFrontdesk(id, entityId)
        end
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
                    SetTimeout(150, function()
                        OpenFrontdeskDutyLogs(id, entityId, data)
                    end)
                end,
            }
        end
        if Config.Frontdesk.requestOfficer.enabled then
            options[#options+1] = {
                title = _L("request_officer"),
                description = _L("request_officer_description"),
                icon = "phone",
                onSelect = function()
                    OpenFrontdeskRequestOfficerForm(id, entityId, data)
                end,
            }
        end
        if Config.Frontdesk.applyForDepartment.enabled then
            options[#options+1] = {
                title = _L("apply_for_department", Departments[id].label),
                description = _L("apply_for_department_description"),
                icon = "clipboard-list",
                onSelect = function()
                    OpenFrontdeskApplyForDepartment(id, entityId, data)
                end,
            }
        end
        if Config.Frontdesk.fileReport.enabled then
            options[#options+1] = {
            title = _L("file_report"),
                description = _L("file_report_description"),
                icon = "clipboard-list",
                onSelect = function()
                    OpenFrontdeskFileReport(id, entityId, data)
                end,
            }
        end
        if #options == 0 then
            return ShowNotification(_L("no_options"))
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
        locations = {},
    }
    for i=1, #Departments[id].locations do
        local entity = Departments[id].locations[i]
        if entity.type == "frontdesk" then
            localDepartment.locations[#localDepartment.locations+1] = {
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

function ExecuteIntegration(integration, ...)
    if Config.Integrations and Config.Integrations[integration] and Config.Integrations[integration].client then
        Config.Integrations[integration].client(...)
    end
end

RegisterNUICallback("getPlayers", function(data, cb)
    ServerCallback("pickle_policejob:getPlayers", function(players)
        cb({
            players = players,
        })
    end)
end)

RegisterNUICallback("pageLoaded", function(data, cb)
    cb("ok")
    while not Inventory or not Inventory.Ready do Wait(100) end
    SendNUIMessage({
        type = "setConfig",
        config = {
            imageDirectory = Config.ImageDirectory,
            identifier = "char:1",
            locale = Language[Config.Language],
            countryCode = Config.Currency.countryCode,
            currency = Config.Currency.currency,
            items = Inventory.Items,
            policeArmory = Config.PoliceArmory or {},
            policeGarage = Config.PoliceGarage or {},
            locationTypes = {
                ["front_desk"] = {
                    locations = {}
                },
                ["police_garage"] = {
                    locations = {"spawn"}
                },
                ["police_armory"] = {
                    locations = {}
                },
            }
        }
    })
end)

RegisterNetEvent("pickle_policejob:integration", function(integration, ...)
    ExecuteIntegration(integration, ...)
end)

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

RegisterNetEvent("pickle_policejob:deleteDepartment", function(id)
    -- TODO: Remove locations and cleanup local departments
    Departments[id] = nil
    for k, v in pairs(LocalDepartments) do
        if k == id then
            LocalDepartments[k] = nil
        end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent("pickle_policejob:initializePlayer")
    end
end)