local viewingFines = false

function ViewFine(serverId, fine)
    local menuId = "pickle_policejob:fines:view_fine"
    local options = {
        {
            title = _L("fine_issuing_department"),
            description = fine.departmentLabel,
            icon = "fas fa-user",
        },
        {
            title = _L("fine_issuer"),
            description = fine.issuingName,
            icon = "fas fa-user",
        },
        {
            title = _L("fine_amount"),
            description = NumberWithCommas(fine.amount),
            icon = Config.TargetIcons.fines,
        },
        {
            title = _L("fine_description"),
            description = fine.description,
            icon = "fas fa-file-alt",
        },
        {
            title = _L("fine_time"),
            description = fine.datetime,
            icon = "fas fa-clock",
        },
    }
    if serverId == GetPlayerServerId(PlayerId()) then
        table.insert(options, {
            title = _L("fine_pay"),
            description = _L("fine_pay_description"),
            icon = "fas fa-money-bill-wave",
            onSelect = function()
                TriggerServerEvent("pickle_policejob:fines:payFine", fine.id)
                SetTimeout(100, function()
                    ViewFines(serverId)
                end)
            end
        })
    else
        table.insert(options, {
            title = _L("fine_remove"),
            description = _L("fine_remove_description"),
            icon = "fas fa-money-bill-wave",
            onSelect = function()
                TriggerServerEvent("pickle_policejob:fines:removeFine", fine.id)
                SetTimeout(100, function()
                    ViewFines(serverId)
                end)
            end
        })
    end
    lib.registerContext({
        id = menuId,
        title = fine.title,
        options = options,
        onExit = function()
            viewingFines = false
            SetTimeout(100, function()
                ViewFines(serverId)
            end)
        end
    })
    lib.showContext(menuId)
end


function ViewFines(serverId)
    if viewingFines then return end
    if not serverId then serverId = GetPlayerServerId(PlayerId()) end
    viewingFines = true
    lib.callback("pickle_policejob:fines:view", false, function(result)
        local menuId = "pickle_policejob:fines:view"
        local options = {}
        if serverId ~= GetPlayerServerId(PlayerId()) and IsPlayerOnDuty() then
            table.insert(options, {
                title = _L("write_fine"),
                description = _L("write_fine_description"),
                onSelect = function()
                    viewingFines = false
                    local input = lib.inputDialog(_L("write_fine"), {
                        {type = 'number', label = _L("fine_amount"), placeholder = _L("fine_amount_description"), default = math.floor(Config.Fines.maxFineAmount / 100), required = true, min = 1, max = Config.Fines.maxFineAmount},
                        {type = 'input', label = _L("fine_title"), placeholder = _L("fine_title_description"), required = true},
                        {type = 'textarea', label = _L("fine_description"), placeholder = _L("fine_description_description"), required = true},
                    })
                    if input then
                        TriggerServerEvent("pickle_policejob:fines:createFine", serverId, tonumber(input[1]) or 1, input[2] or "Untitled", input[3] or "No description")
                    end
                    SetTimeout(100, function()
                        ViewFines(serverId)
                    end)
                end
            })
        end
        for _, fine in pairs(result.fines) do
            table.insert(options, {
                title = fine.title .. " - " .. NumberWithCommas(fine.amount),
                description = fine.description,
                onSelect = function()
                    viewingFines = false
                    SetTimeout(100, function()
                        ViewFine(serverId, fine)
                    end)
                end
            })
        end
        if #result.fines == 0 then
            table.insert(options, {
                title = _L("no_fines"),
                disabled = true,
                onSelect = function()
                    viewingFines = false
                end
            })
        end
        lib.registerContext({
            id = menuId,
            title = (serverId == GetPlayerServerId(PlayerId()) and _L("view_fines") or _L("view_fines_other", result.name)),
            options = options,
            onExit = function()
                viewingFines = false
                if (serverId ~= GetPlayerServerId(PlayerId())) then
                    SetTimeout(100, function()
                        OpenPoliceActionsMenu()
                    end)
                end
            end
        })
        lib.showContext(menuId)
    end, serverId)
end

RegisterCommand(Config.Fines.viewFinesCommand, function()
    ViewFines()
end)