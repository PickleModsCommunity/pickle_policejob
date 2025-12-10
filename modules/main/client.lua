local LocalDepartments = {}
local CurrentDepartment = nil
local OnDuty = false
local PAGE_READY = false

function IsPlayerOnDuty()
    return OnDuty
end

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
    lib.callback("pickle_policejob:openFrontdesk", false, function(data)
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
                    OpenFrontdeskRequestOfficer(id)
                end,
            }
        end
        if not data.departmentId and Config.Frontdesk.applyForDepartment.enabled then
            options[#options+1] = {
                title = _L("apply_for_department", Departments[id].label),
                description = _L("apply_for_department_description"),
                icon = "clipboard-list",
                onSelect = function()
                    OpenFrontdeskApplyForDepartment(id)
                end,
            }
        end
        if Config.Frontdesk.fileReport.enabled then
            options[#options+1] = {
            title = _L("file_report"),
                description = _L("file_report_description"),
                icon = "clipboard-list",
                onSelect = function()
                    OpenFrontdeskFileReport(id)
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

function OpenLocker(id, locationId)
    Inventory.OpenStash("police_locker", true)
end

function OpenFrontdeskApplyForDepartment(id)
    local department = Departments[id]
    if not department then return end
    local results = lib.inputDialog(_L("apply_for_department_title", department.label), Config.Frontdesk.applyForDepartment.fields)
    if not results then return end
    TriggerServerEvent("pickle_policejob:submitDepartmentApplication", id, results)
end

function OpenFrontdeskFileReport(id)
    local department = Departments[id]
    if not department then return end
    local results = lib.inputDialog(_L("file_report_form_title"), Config.Frontdesk.fileReport.fields)
    if not results then return end
    TriggerServerEvent("pickle_policejob:submitReport", id, results)
end

function OpenFrontdeskRequestOfficer(id)
    local department = Departments[id]
    if not department then return end
    local results = lib.inputDialog(_L("request_officer_form_title"), Config.Frontdesk.requestOfficer.fields)
    if not results then return end
    TriggerServerEvent("pickle_policejob:submitRequestOfficer", id, results)
end

function UnrenderDepartmentLocation(id, locationId, dontRemove)
    for i=1, #LocalDepartments[id].locations do
        if LocalDepartments[id].locations[i].id == locationId then
            if LocalDepartments[id].locations[i].interact then
                DeleteInteraction(LocalDepartments[id].locations[i].interact)
            end
            if LocalDepartments[id].locations[i].npc then
                DeleteEntity(LocalDepartments[id].locations[i].npc)
            end
            if LocalDepartments[id].locations[i].additionalInteracts then
                for j=1, #LocalDepartments[id].locations[i].additionalInteracts do
                    DeleteInteraction(LocalDepartments[id].locations[i].additionalInteracts[j])
                end
            end
            if not dontRemove then
                table.remove(LocalDepartments[id].locations, i)
            end
            break
        end
    end
end

function RenderDepartmentLocation(id, locationId)
    local location
    for i=1, #Departments[id].locations do
        if Departments[id].locations[i].id == locationId then
            location = Departments[id].locations[i]
            break
        end
    end
    if not location then return end
    if location.type == "front_desk" then
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        if location.settings.ped and location.settings.ped ~= "" then
            coords = coords + vector3(0.0, 0.0, 1.0)
        end
        local npc
        if location.settings.ped and location.settings.ped ~= "" then
            local pedCfg
            for i=1, #Config.Peds do
                if Config.Peds[i].model == location.settings.ped then
                    pedCfg = Config.Peds[i]
                    break
                end
            end
            if pedCfg then
                npc = CreateNPC(location.settings.ped, coords.x, coords.y, coords.z - 1.0, heading)
                for i=1, #pedCfg.pedComponents do
                    SetPedComponentVariation(npc, pedCfg.pedComponents[i].id, pedCfg.pedComponents[i].drawable, pedCfg.pedComponents[i].texture, 0)
                end
                SetPedKeepTask(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetPedFleeAttributes(npc, 0, false)
                SetPedDiesWhenInjured(npc, false)
                FreezeEntityPosition(npc, true)
            end
        end
        LocalDepartments[id].locations[#LocalDepartments[id].locations+1] = {
            id = locationId,
            npc = npc,
            interact = CreateInteraction({
                label = _L("interact_frontdesk"),
                icon = Config.TargetIcons["frontdesk"],
                coords = coords,
                heading = heading,
                model = nil,
            }, function()
                OpenFrontdesk(id, locationId)
            end)
        }
    elseif location.type == "locker" then
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        
        LocalDepartments[id].locations[#LocalDepartments[id].locations+1] = {
            id = locationId,
            interact = CreateInteraction({
                label = _L("interact_locker"),
                icon = Config.TargetIcons["locker"],
                coords = coords,
                heading = heading,
                model = nil,
            }, function()
                OpenLocker(id, locationId)
            end)
        }
    elseif location.type == "computer" then
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        if location.settings.ped and location.settings.ped ~= "" then
            coords = coords + vector3(0.0, 0.0, 1.0)
        end
        LocalDepartments[id].locations[#LocalDepartments[id].locations+1] = {
            id = locationId,
            interact = CreateInteraction({
                label = _L("location_computer"),
                icon = Config.TargetIcons["computer"],
                coords = coords,
                heading = heading,
            }, function()
                OpenComputer(id, locationId)
            end)
        }
    elseif location.type == "armory" then
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        if location.settings.ped and location.settings.ped ~= "" then
            coords = coords + vector3(0.0, 0.0, 1.0)
        end
        LocalDepartments[id].locations[#LocalDepartments[id].locations+1] = {
            id = locationId,    
            interact = CreateInteraction({
                label = _L("location_armory"),
                icon = Config.TargetIcons["armory"],
                coords = coords,
                heading = heading,
                model = (location.settings.ped and location.settings.ped ~= "") and { modelType = "ped", hash = GetHashKey(location.settings.ped) } or nil,
            }, function()   
                OpenArmory(id, locationId)
            end)
        }
    elseif location.type == "garage" then
        local coords = location.positions.point.coords
        local heading = location.positions.point.rotation.z
        if location.settings.ped and location.settings.ped ~= "" then
            coords = coords + vector3(0.0, 0.0, 1.0)
        end
        LocalDepartments[id].locations[#LocalDepartments[id].locations+1] = {   
            id = locationId,
            interact = CreateInteraction({
                label = Config.PoliceGarageTypes[location.settings.garageType]?.label or "ERR_GARAGE_UNKNOWN_TYPE",
                icon = Config.TargetIcons["garage"],
                coords = coords,
                heading = heading,
                model = (location.settings.ped and location.settings.ped ~= "") and { modelType = "ped", hash = GetHashKey(location.settings.ped) } or nil,
            }, function()
                OpenVehicleSpawn(id, locationId)
            end),
            additionalInteracts = {
                CreateInteraction({
                    label = _L("return_vehicle"),
                    coords = location.positions.vehicle_spawn.coords,
                    heading = location.positions.vehicle_spawn.rotation.z,
                    vehicleInteract = true,
                    interactRadius = 4.0,
                }, function()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if not vehicle then return ShowNotification(_L("not_in_vehicle")) end
                    TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
                    Wait(3000)
                    DeleteEntity(vehicle)
                end)
            }
        }
    end
end

function EnsureDepartmentLocation(id, locationId)
    UnrenderDepartmentLocation(id, locationId)
    RenderDepartmentLocation(id, locationId)
end

function EnsureDepartment(id)
    if LocalDepartments[id] then return end
    local showBlip = true
    if Departments[id].misc and Departments[id].misc.showBlip ~= nil then
        showBlip = Departments[id].misc.showBlip
    end
    LocalDepartments[id] = {
        blip = showBlip and CreateDepartmentBlip(id) or nil,
        locations = {},
    }
    for i=1, #Departments[id].locations do
        EnsureDepartmentLocation(id, Departments[id].locations[i].id)
    end
end

function ExecuteIntegration(integration, ...)
    if Config.Integrations and Config.Integrations[integration] and Config.Integrations[integration].client then
        Config.Integrations[integration].client(...)
    end
end

function GetDepartmentLocation(departmentId, locationId)
    for i=1, #Departments[departmentId].locations do
        if Departments[departmentId].locations[i].id == locationId then
            return Departments[departmentId].locations[i]
        end
    end
end

function CreateDepartmentBlip(departmentId) 
    local department = Departments[departmentId]
    if not department then return end
    local coords = department.location and department.location.coords or vector3(0.0, 0.0, 0.0)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipCfg = Config.DepartmentBlip or {}
    SetBlipSprite(blip, blipCfg.sprite or 1)
    SetBlipDisplay(blip, blipCfg.display or 4)
    SetBlipScale(blip, blipCfg.scale or 1.0)
    SetBlipColour(blip, blipCfg.color or 0)
    SetBlipAsShortRange(blip, true)
    local category = blipCfg.category or 40
    SetBlipCategory(blip, category)
    AddTextEntry("BLIP_CAT_" .. category, _L("blip_department"))
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(department.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

RegisterNUICallback("getPlayers", function(data, cb)
    lib.callback("pickle_policejob:getPlayers", false, function(players)
        cb({
            players = players,
        })
    end)
end)

RegisterNUICallback("pageLoaded", function(data, cb)
    cb("ok")
    PAGE_READY = true
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
    if not LocalDepartments[id] then return end
    if LocalDepartments[id].blip then
        RemoveBlip(LocalDepartments[id].blip)
    end
    local locations = LocalDepartments[id].locations
    for i=1, #locations do
        UnrenderDepartmentLocation(id, locations[i].id, true)
    end
    LocalDepartments[id] = nil
end)

RegisterNetEvent("pickle_policejob:updateDepartment", function(data)
    if data.type == "createLocation" then
        Departments[data.departmentId].locations[#Departments[data.departmentId].locations+1] = data.location
        EnsureDepartmentLocation(data.departmentId, data.location.id)
    elseif data.type == "updateDepartmentLocation" then
        Departments[data.departmentId].location = data.location
        if LocalDepartments[data.departmentId].blip then
            RemoveBlip(LocalDepartments[data.departmentId].blip)
        end
        local showBlip = true
        if Departments[data.departmentId].misc and Departments[data.departmentId].misc.showBlip ~= nil then
            showBlip = Departments[data.departmentId].misc.showBlip
        end
        LocalDepartments[data.departmentId].blip = showBlip and CreateDepartmentBlip(data.departmentId) or nil
    elseif data.type == "toggleBlip" then
        Departments[data.departmentId].misc = Departments[data.departmentId].misc or {}
        Departments[data.departmentId].misc.showBlip = data.showBlip
        if LocalDepartments[data.departmentId] then
            if LocalDepartments[data.departmentId].blip then
                RemoveBlip(LocalDepartments[data.departmentId].blip)
            end
            if data.showBlip then
                LocalDepartments[data.departmentId].blip = CreateDepartmentBlip(data.departmentId)
            else
                LocalDepartments[data.departmentId].blip = nil
            end
        end
    elseif data.type == "updateLocation" then
        local updatedLocation = false
        for i=1, #Departments[data.departmentId].locations do
            if Departments[data.departmentId].locations[i].id == data.locationId then
                Departments[data.departmentId].locations[i] = data.location
                updatedLocation = true
                break
            end
        end
        if not updatedLocation then
            Departments[data.departmentId].locations[#Departments[data.departmentId].locations+1] = data.location
        end
        EnsureDepartmentLocation(data.departmentId, data.locationId)
    elseif data.type == "deleteLocation" then
        UnrenderDepartmentLocation(data.departmentId, data.locationId)
        for i=1, #Departments[data.departmentId].locations do
            if Departments[data.departmentId].locations[i].id == data.locationId then
                table.remove(Departments[data.departmentId].locations, i)
                break
            end
        end
    end
end)

RegisterNetEvent("pickle_policejob:initializePlayer", function()
    while not PAGE_READY do Wait(100) end
    lib.callback("pickle_policejob:getPlayerInfo", false, function(player)
        while not Inventory or not Inventory.Ready do Wait(100) end
        SendNUIMessage({
            type = "setConfig",
            config = {
                bailAndBounty = GetResourceState("pickle_bailbounty") == "started",
                disableWithdraw = Config.Finance.disableWithdraw,
                evidenceEnabled = Config.Evidence.enabled,
                imageDirectory = Config.ImageDirectory,
                imageExtension = Config.ImageExtension,
                identifier = player.identifier,
                name = player.name,
                locale = Language[Config.Language],
                countryCode = Config.Currency.countryCode,
                currency = Config.Currency.currency,
                items = Inventory.Items,
                jobs = Config.PoliceJobs or {},
                policeArmory = Config.PoliceArmory or {},
                policeGarage = Config.PoliceGarage or {},
                peds = Config.Peds or {},
                garageTypes = Config.PoliceGarageTypes or {},
                locationTypes = LOCATION_TYPES,
            }
        })
    end)
end)

RegisterNetEvent("pickle_policejob:updateOnDuty", function(onDuty)
    OnDuty = onDuty
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        TriggerServerEvent("pickle_policejob:initializePlayer")
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(LocalDepartments) do   
            if v.blip then
                RemoveBlip(v.blip)
            end
            for i=1, #v.locations do    
                UnrenderDepartmentLocation(k, v.locations[i].id, true)
            end
        end
        LocalDepartments = {}
    end
end)