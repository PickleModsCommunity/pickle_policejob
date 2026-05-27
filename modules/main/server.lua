local RecentApplications = {}
local RecentReports = {}
local RecentRequestOfficers = {}

function InitializeDepartment(id, data, dontSync)
    local department = {
        id = id,
        job = data.job,
        label = data.label,
        image = data.image,
        money = data.money,
        location = data.location,
        locations = EnsureDepartmentData("locations", data.locations),
        members = data.members,
        ranks = data.ranks,
        outfits = data.outfits,
        permissions = data.permissions,
        misc = data.misc,
    }
    Departments[id] = department
    if dontSync then return end
    TriggerClientEvent("pickle_policejob:initializeDepartment", -1, id, department)
end

function UpdateDepartmentSQL(id, columnId)
    local department = GetDepartment(id)
    if not department then return end
    if columnId == "label" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET label = @label WHERE id = @id", {
            label = department.label,
            id = id,
        })
    elseif columnId == "image" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET image = @image WHERE id = @id", {
            image = department.image,
            id = id,
        })
    elseif columnId == "money" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET money = @money WHERE id = @id", {
            money = department.money,
            id = id,
        })
    elseif columnId == "job" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET job = @job WHERE id = @id", {
            job = department.job,
            id = id,
        })
    elseif columnId == "location" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET location = @location WHERE id = @id", {
            location = json.encode(department.location),
            id = id,
        })
    elseif columnId == "members" then
        local members = {}
        for i=1, #department.members do
            table.insert(members, RemoveFields(department.members[i], {"onDuty"}))
        end
        MySQL.Async.execute("UPDATE pickle_police_departments SET members = @members WHERE id = @id", {
            members = json.encode(members),
            id = id,
        })
    elseif columnId == "locations" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET locations = @locations WHERE id = @id", {
            locations = json.encode(department.locations),
            id = id,
        })
    elseif columnId == "permissions" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET permissions = @permissions WHERE id = @id", {
            permissions = json.encode(department.permissions),
            id = id,
        })
    elseif columnId == "ranks" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET ranks = @ranks WHERE id = @id", {
            ranks = json.encode(department.ranks),
            id = id,
        })
    elseif columnId == "outfits" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET outfits = @outfits WHERE id = @id", {
            outfits = json.encode(department.outfits),
            id = id,
        })
    elseif columnId == "misc" then
        MySQL.Async.execute("UPDATE pickle_police_departments SET misc = @misc WHERE id = @id", {
            misc = json.encode(department.misc),
            id = id,
        })
    end
end

function DeleteDepartment(id)
    Departments[id] = nil
    TriggerClientEvent("pickle_policejob:deleteDepartment", -1, id)
end

function GetDepartment(id)
    return Departments[id]
end

function GetDepartmentPermission(id, permission)
    local department = GetDepartment(id)
    if not department then return nil end
    return department.permissions[permission]
end

function GetDepartmentMember(id, source)
    local department = GetDepartment(id)
    local identifier
    if type(source) == "string" and not tonumber(source) then
        identifier = source
    else
        identifier = GetIdentifier(source)
    end
    if not department then return nil end
    for i=1, #department.members do
        if department.members[i].identifier == identifier then
            return department.members[i], i, GetSourceFromIdentifier(identifier)
        end
    end
end

function GetPlayerDepartment(source)
    local identifier = GetIdentifier(source)
    for k, v in pairs(Departments) do
        for i=1, #v.members do
            if v.members[i].identifier == identifier then
                return k, v.members[i]
            end
        end
    end
    return nil
end

function GetPlayerDepartmentJob(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return nil end
    local department = Departments[departmentId]
    if not department then return nil end
    local rank, rankIndex = GetDepartmentRank(departmentId, memberData.rankId)
    if not rank then return nil end
    return department.job, rank.jobLevel
end

function GetIdentifierDepartment(identifier)
    for k, v in pairs(Departments) do
        for i=1, #v.members do
            if v.members[i].identifier == identifier then
                return k, v.members[i]
            end
        end
    end
end

function GetDepartmentEntity(id, entityId)
    local department = GetDepartment(id)
    for i=1, #department.locations do
        if department.locations[i].id == entityId then
            return department.locations[i], i
        end
    end
    return nil
end

function AddDepartmentMoney(id, amount)
    local department = GetDepartment(id)
    if not department then return end
    department.money = (department.money or 0) + amount
    UpdateDepartmentSQL(id, "money")
    SendComputerEvent("pickle_policejob:updateComputerDepartment", {
        type = "updateFinance",
        money = department.money,
    })
end

exports("AddDepartmentMoney", AddDepartmentMoney)

function RemoveDepartmentMoney(id, amount)
    local department = GetDepartment(id)
    if not department then return end
    department.money = (department.money or 0) - amount
    UpdateDepartmentSQL(id, "money")
end 

exports("RemoveDepartmentMoney", RemoveDepartmentMoney)

function GetDepartmentMoney(id)
    local department = GetDepartment(id)
    if not department then return 0 end
    return department.money
end

exports("GetDepartmentMoney", GetDepartmentMoney)

function AddDepartmentTransaction(id, source, transactionType, amount, reason)
    local department = GetDepartment(id)
    if not department then return end
    table.insert(department.misc.transactions, 1, {
        id = os.time() .. "_" .. math.random(1, 50),
        identifier = source == -1 and "SYSTEM" or GetIdentifier(source),
        name = source == -1 and _L("system") or GetPlayerCharacterName(source),
        amount = amount,
        reason = reason,
        type = transactionType,
        time = os.time(),
    })
    if #department.misc.transactions > Config.Finance.maxTransactions then
        table.remove(department.misc.transactions, Config.Finance.maxTransactions)
    end
    UpdateDepartmentSQL(id, "misc")
    SendComputerEvent("pickle_policejob:updateComputerDepartment", {
        type = "updateTransactions",
        transactions = department.misc.transactions,
    })
end

function IsPlayerOnDuty(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return false end
    return memberData.onDuty
end

function EnsureDepartmentData(key, data)
    if not data then return end
    if key == "label" then
        return data or "ERR_UNKNOWN"
    elseif key == "location" then
        if not data or not data.coords or data.rotation == nil then
            return {
                coords = vector3(0.0, 0.0, 0.0),
                rotation = vector3(0.0, 0.0, 0.0),
            }
        else
            return {
                coords = vector3(data.coords.x, data.coords.y, data.coords.z),
                rotation = vector3(data.rotation.x, data.rotation.y, data.rotation.z),
            }
        end
    elseif key == "locations" then
        if not data or type(data) ~= "table" then return {} end
        local locations = {}
        for i=1, #data do
            local positions = {}
            for k, v in pairs(data[i].positions) do
                positions[k] = EnsureDepartmentData("location", v)
            end
            locations[#locations+1] = {
                id = data[i].id,
                type = data[i].type,
                positions = positions,
                settings = data[i].settings or {},
            }
        end
        return locations
    elseif key == "misc" then
        if not data or type(data) ~= "table" then return {} end
        if not data.transactions or type(data.transactions) ~= "table" then data.transactions = {} end
        return data
    else
        return data or {}
    end
end

function DoesPlayerHaveEntityPermission(source, id, entityId, onDutyRequired)
    local departmentId, memberData = GetPlayerDepartment(source)
    local entity, entityIndex = GetDepartmentEntity(id, entityId)
    if not entity then return false end
    if onDutyRequired and (not departmentId or not memberData.onDuty) then return false end
    if not entity.permissions or #entity.permissions == 0 then return true end
    if not memberData or not memberData.permissions or #memberData.permissions == 0 then return false end
    for i=1, #entity.permissions do
        for j=1, #memberData.permissions do
            if entity.permissions[i] == memberData.permissions[j] then
                return true
            end
        end
    end
    return false
end

function ExecuteIntegration(source, integration, ...)
    if Config.Integrations and Config.Integrations[integration] and Config.Integrations[integration].server then
        Config.Integrations[integration].server(source, ...)
        if Config.Integrations[integration].client then
            TriggerClientEvent("pickle_policejob:integration", source, integration, ...)
        end
    end
end

function SetPlayerDuty(source, onDuty, report)
    report = report or ""
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return ShowNotification(source, _L("no_department_permission")) end
    local department = Departments[departmentId]
    local rank, rankIndex = GetDepartmentRank(departmentId, memberData.rankId)
    if onDuty and not memberData.onDuty then
        memberData.onDuty = os.time()
        SetPlayerFrameworkDuty(source, true)
        ShowNotification(source, _L("duty_on"))
        ExecuteIntegration(source, "duty", departmentId, true)
        TriggerClientEvent("pickle_policejob:updateOnDuty", source, true)
    elseif not onDuty and memberData.onDuty then
        local duration = os.time() - memberData.onDuty
        memberData.onDutyTime = (memberData.onDutyTime or 0) + duration
        memberData.onDuty = nil
        memberData.recentDutyLogs = memberData.recentDutyLogs or {}
        table.insert(memberData.recentDutyLogs, 1, {
            report = string.len(report) > 0 and report or nil,
            finish = os.time(),
            finishTimestamp = GetFormattedDate(os.time()),
            startTimestamp = GetFormattedDate(os.time() - duration),
            duration = duration
        })
        if #memberData.recentDutyLogs > 10 then
            table.remove(memberData.recentDutyLogs)
        end
        SetPlayerFrameworkDuty(source, false)
        ShowNotification(source, _L("duty_off"))
        UpdateDepartmentSQL(departmentId, "members")
        ExecuteIntegration(source, "duty", departmentId, false, report)
        TriggerClientEvent("pickle_policejob:updateOnDuty", source, false)
    end
end

function GetDepartmentRank(id, rankId)
    local department = GetDepartment(id)
    if not department then return nil end
    for i=1, #department.ranks do
        if department.ranks[i].rankId == rankId then
            return department.ranks[i], i
        end
    end
    return nil
end

function CanRankManageRank(departmentId, rankId, targetRankId)
    local rank, rankIndex = GetDepartmentRank(departmentId, rankId)
    local targetRank, targetRankIndex = GetDepartmentRank(departmentId, targetRankId)
    if not rank or not targetRank then return false end
    if rankIndex == 1 then return true end -- If this is the leader rank, they can manage all ranks
    for i=1, #targetRank.managingRankIds do
        if targetRank.managingRankIds[i] == rankId then return true end
    end
    return false
end

function CanRankManagePermission(departmentId, rankId, permission)
    local department = GetDepartment(departmentId)
    if not department then return false end
    local permissionData = GetDepartmentPermission(departmentId, permission)
    if not permissionData then return false end
    if department.ranks[1].rankId == rankId then return true end -- If this is the leader rank, they can manage all permissions
    for i=1, #permissionData.managingRankIds do
        if permissionData.managingRankIds[i] == rankId then return true end
    end
    return false
end

function IsPlayerDepartmentLeader(source)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return false end
    local department = GetDepartment(departmentId)
    if not department then return false end
    local rank, rankIndex = GetDepartmentRank(departmentId, memberData.rankId)
    if not rank then return false end
    return rankIndex == 1
end

function CanRankAccessEntry(departmentId, rankId, entryId, entryType)
    local department = GetDepartment(departmentId)
    if not department then return false end
    if department.ranks[1].rankId == rankId then
        return true
    end
    for i=#department.ranks, 1, -1 do
        local rank = department.ranks[i]
        for i=1, #rank[entryType] do 
            local target = rank[entryType][i]
            if target == entryId then
                return true
            end
        end
        if rank.rankId == rankId then
            break
        end
    end
    return false
end

function CanPermissionsAccessEntry(departmentId, permissions, entryId, entryType)
    local department = GetDepartment(departmentId)
    if not department then return false end
    for i=1, #permissions do
        local permission = department.permissions[permissions[i]]
        for j=1, #permission[entryType] do
            local target = permission[entryType][j]
            if target == entryId then
                return true
            end
        end
    end
    return false
end

function GetTotalCopsOnline()
    local total = 0
    for _, player in pairs(GetPlayers()) do
        if IsPlayerOnDuty(player) then
            total = total + 1
        end
    end
    return total
end

function EnsurePlayerDuty(source, onDuty, checkDuty)
    if checkDuty and not onDuty then return end
    local departmentId, memberData = GetPlayerDepartment(source)
    if departmentId then
        local department = Departments[departmentId]
        local rank, rankIndex = GetDepartmentRank(departmentId, memberData.rankId)
        local isDuty = IsPlayerOnDuty(source)
        if GetPlayerJob(source) and department.job == GetPlayerJob(source).name then
            SetPlayerDuty(source, true)
        elseif isDuty then
            SetPlayerDuty(source, false)
        end
    end
end

exports("GetTotalCopsOnline", GetTotalCopsOnline)

exports("GetDepartment", GetDepartment)
exports("GetDepartmentPermission", GetDepartmentPermission)
exports("GetDepartmentMember", GetDepartmentMember)
exports("GetDepartmentRank", GetDepartmentRank)
exports("GetDepartmentEntity", GetDepartmentEntity)
exports("GetPlayerDepartment", GetPlayerDepartment)
exports("GetPlayerDepartmentJob", GetPlayerDepartmentJob)
exports("GetIdentifierDepartment", GetIdentifierDepartment)
exports("IsPlayerOnDuty", IsPlayerOnDuty)
exports("SetPlayerDuty", SetPlayerDuty)
exports("IsPlayerDepartmentLeader", IsPlayerDepartmentLeader)
exports("DoesPlayerHaveEntityPermission", DoesPlayerHaveEntityPermission)
exports("AddDepartmentTransaction", AddDepartmentTransaction)

function GenerateApplicationContent(results)
    local fields = Config.Frontdesk.applyForDepartment.fields
    local content = ""
    for i=1, #fields do
        if not results[i] then results[i] = "No answer provided" end
        content = content .. "<div><b>".. fields[i].label .. "</b>:</div><hr/><div>".. results[i] .. "</div>"
    end
    return content
end

function GenerateReportContent(results)
    local fields = Config.Frontdesk.fileReport.fields
    local content = ""
    for i=1, #fields do
        if not results[i] then results[i] = "No answer provided" end
        content = content .. "<div><b>".. fields[i].label .. "</b>:</div><hr/><div>".. results[i] .. "</div>"
    end
    return content
end

lib.callback.register("pickle_policejob:openFrontdesk", function(source, id)
    local department = GetDepartment(id)
    local departmentId, memberData = GetPlayerDepartment(source)
    local time = os.time()
    return {
        departmentId = departmentId,
        memberData = memberData,
        time = time,
    }
end)

lib.callback.register("pickle_policejob:getPlayers", function(source)
    local players = {}
    for k, v in pairs(GetPlayers()) do
        players[#players + 1] = {
            source = tonumber(v),
            identifier = GetIdentifier(v),
            name = GetPlayerCharacterName(v),
        }
    end
    return players
end)

lib.callback.register("pickle_policejob:getPlayerInfo", function(source)
    return {
        identifier = GetIdentifier(source),
        name = GetPlayerCharacterName(source),
    }
end)

RegisterNetEvent("pickle_policejob:toggleDuty", function(id, entityId, report)
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId or id ~= departmentId or not DoesPlayerHaveEntityPermission(source, id, entityId) then return ShowNotification(source, _L("no_department_permission")) end
    SetPlayerDuty(source, not memberData.onDuty, report)
end)

if Config.CommandClocking and Config.CommandClocking.enabled then
    RegisterCommand(Config.CommandClocking.clockin, function(source, args, rawCommand)
        local departmentId, memberData = GetPlayerDepartment(source)
        if not departmentId then return ShowNotification(source, _L("no_department_permission")) end
        if memberData.onDuty then return ShowNotification(source, _L("already_on_duty")) end
        SetPlayerDuty(source, true)
    end, false)

    RegisterCommand(Config.CommandClocking.clockout, function(source, args, rawCommand)
        local departmentId, memberData = GetPlayerDepartment(source)
        if not departmentId then return ShowNotification(source, _L("no_department_permission")) end
        if not memberData.onDuty then return ShowNotification(source, _L("not_on_duty")) end
        local report = table.concat(args, " ") or ""
        SetPlayerDuty(source, false, report)
    end, false)
end

RegisterNetEvent("pickle_policejob:initializePlayer", function()
    local source = source
    CreateThread(function()
        while not Inventory.Ready do
            Wait(100)
        end
        EnsurePlayerDuty(source)
        TriggerClientEvent("pickle_policejob:initializePlayer", source)
        TriggerClientEvent("pickle_policejob:setupInventory", source, Inventory.Items)
        TriggerClientEvent("pickle_policejob:initializeDepartment", source, Departments)
        TriggerClientEvent("pickle_policejob:updateOnDuty", source, IsPlayerOnDuty(source))
    end)
end)

RegisterNetEvent("pickle_policejob:submitDepartmentApplication", function(id, results)
    local source = source
    local department = GetDepartment(id)
    if not department then return end
    if RecentApplications[source] then
        for i=1, #RecentApplications[source] do
            if RecentApplications[source][i] == id then
                return ShowNotification(source, _L("already_applied_for_department"))
            end
        end
    else
        RecentApplications[source] = {}
    end
    table.insert(RecentApplications[source], id)
    local file = {
        name = _L("application_title", GetPlayerCharacterName(source)),
        authorIdentifier = GetIdentifier(source),
        datetime = os.time(),
        document = {
            header = {
                title = toupper(department.label),
                image = department.image,
                leftInfo = {"<b>".. GetPlayerCharacterName(source) .. "</b>", "Los Santos, San Andreas"},
                rightInfo = {"<b>".. _L("applicant") .. "</b>", GetFormattedDate(os.time())},
            },
            subContent = {},
            enableContent = true,
            content = GenerateApplicationContent(results)
        },
        evidence = {},
    }
    local result = MySQL.query.await("INSERT INTO pickle_police_files (departmentId, name, authorIdentifier, datetime, document, evidence) VALUES (?, ?, ?, ?, ?, ?)", {
        id,
        file.name,
        file.authorIdentifier,
        file.datetime,
        json.encode(file.document),
        json.encode(file.evidence),
    })
    file.id = result.insertId
    Inventory.AddItem(source, "police_report", 1, {
        fileId = file.id,
    })
    ShowNotification(source, _L("application_submitted", file.id))
end)

RegisterNetEvent("pickle_policejob:submitReport", function(id, results)
    local source = source
    local department = GetDepartment(id)
    if not department then return end
    if RecentReports[source] then
        for i=1, #RecentReports[source] do
            if RecentReports[source][i] == id then
                return ShowNotification(source, _L("already_filed_report"))
            end
        end
    else
        RecentReports[source] = {}
    end
    table.insert(RecentReports[source], id)
    local file = {
        name = _L("report_title", GetPlayerCharacterName(source)),
        authorIdentifier = GetIdentifier(source),
        datetime = os.time(),
        document = {
            header = {
                title = toupper(department.label),
                image = department.image,
                leftInfo = {"<b>".. GetPlayerCharacterName(source) .. "</b>", "Los Santos, San Andreas"},
                rightInfo = {"<b>".. _L("complaintant") .. "</b>", GetFormattedDate(os.time())},
            },
            subContent = {},
            enableContent = true,
            content = GenerateReportContent(results)
        },
        evidence = {},
    }
    local result = MySQL.query.await("INSERT INTO pickle_police_files (departmentId, name, authorIdentifier, datetime, document, evidence) VALUES (?, ?, ?, ?, ?, ?)", {
        id,
        file.name,
        file.authorIdentifier,
        file.datetime,
        json.encode(file.document),
        json.encode(file.evidence),
    })
    file.id = result.insertId
    Inventory.AddItem(source, "police_report", 1, {
        fileId = file.id,
    })
    ShowNotification(source, _L("report_submitted", file.id))
end)

RegisterNetEvent("pickle_policejob:submitRequestOfficer", function(id, results)
    local source = source
    local department = GetDepartment(id)
    if not department then return end
    if RecentRequestOfficers[source] then
        if RecentRequestOfficers[source] > os.time() then
            local timeLeft = RecentRequestOfficers[source] - os.time()
            return ShowNotification(source, _L("request_officer_timeout", GetFormattedTime(timeLeft)))
        end
    else
        RecentRequestOfficers[source] = os.time() + Config.Frontdesk.requestOfficer.timeout
    end
    for _, member in pairs(department.members) do
        local source = GetSourceFromIdentifier(member.identifier)
        if member.onDuty and source then
            ShowNotification(source, _L("request_officer_requested"))
        end
    end
    ShowNotification(source, _L("request_officer_submitted"))
    ExecuteIntegration(source, "requestOfficer", id, results)
end)

AddEventHandler("playerDropped", function()
    local source = source
    local departmentId, memberData = GetPlayerDepartment(source)
    if not departmentId then return end
    if memberData.onDuty then
        SetPlayerDuty(source, false)
    end
end)

lib.cron.new(Config.Finance.salarySchedule, function()
    for _, department in pairs(Departments) do
        local totalCost = 0
        local totalMembers = 0
        for _, member in pairs(department.members) do
            local source = GetSourceFromIdentifier(member.identifier)
            if member.onDuty and source then
                local rank = GetDepartmentRank(department.id, member.rankId)
                if rank then 
                    totalCost = totalCost + (rank.salary or 0)
                    totalMembers = totalMembers + 1
                end
            end
        end
        if totalCost > 0 then
            local payMembers = false
            local money = GetDepartmentMoney(department.id)
            if Config.Finance.deductSalaryFromDepartment then
                if money >= totalCost then
                    RemoveDepartmentMoney(department.id, totalCost)
                    AddDepartmentTransaction(department.id, -1, "withdraw", totalCost, _L("salary_paid_reason", totalMembers))
                    payMembers = true
                end
            else
                payMembers = true
            end
            for _, member in pairs(department.members) do
                local source = GetSourceFromIdentifier(member.identifier)
                if member.onDuty and source then
                    if payMembers then
                        local rank = GetDepartmentRank(department.id, member.rankId)
                        AddMoney(source, rank.salary, "bank")
                        ShowNotification(source, _L("salary_paid",  NumberWithCommas(rank.salary)))
                    else
                        ShowNotification(source, _L("salary_not_paid"))
                    end
                end
            end
        end
    end
end)

lib.cron.new(Config.Finance.fundingSchedule, function()
    for _, department in pairs(Departments) do
        AddDepartmentMoney(department.id, Config.Finance.funding)
        AddDepartmentTransaction(department.id, -1, "deposit", Config.Finance.funding, _L("funding_paid_reason"))
    end
end)

MySQL.ready(function()
    -- local department = Config.Departments[11]
    -- MySQL.Async.execute("INSERT IGNORE INTO pickle_police_departments (id, label, location, members, locations, permissions, ranks, outfits) VALUES (@id, @label, @location, @members, @locations, @permissions, @ranks, @outfits)", {
    --     id = 11,
    --     label = department.label,
    --     location = json.encode(department.location),
    --     members = json.encode(department.members),
    --     locations = json.encode(department.locations),
    --     permissions = json.encode(department.permissions),
    --     ranks = json.encode(department.ranks),
    --     outfits = json.encode(department.outfits),
    -- })
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pickle_police_departments` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `job` VARCHAR(255) NOT NULL,
            `label` VARCHAR(255) NOT NULL,
            `image` TEXT NOT NULL,
            `money` INT NOT NULL DEFAULT 0,
            `location` JSON NOT NULL,
            `locations` JSON NOT NULL,
            `members` JSON NOT NULL,
            `permissions` JSON NOT NULL,
            `ranks` JSON NOT NULL,
            `outfits` JSON NOT NULL,
            `misc` JSON NOT NULL,
            PRIMARY KEY (`id`)
        )
    ]], function()
        MySQL.Async.fetchAll("SELECT * FROM pickle_police_departments", {}, function(result)
            for k, v in pairs(result) do
                if not Config.PoliceJobs[v.job] then
                    print("ERROR: Job not found in Config.PoliceJobs, this will break the script: ", v.job, "Department: ", v.label)
                end
                InitializeDepartment(v.id, {
                    label = EnsureDepartmentData("label", v.label),
                    image = v.image,
                    job = v.job,
                    money = v.money,
                    location = EnsureDepartmentData("location", json.decode(v.location)),
                    members = EnsureDepartmentData("members", json.decode(v.members)),
                    locations = EnsureDepartmentData("locations", json.decode(v.locations)),
                    permissions = EnsureDepartmentData("permissions", json.decode(v.permissions)),
                    ranks = EnsureDepartmentData("ranks", json.decode(v.ranks)),
                    outfits = EnsureDepartmentData("outfits", json.decode(v.outfits)),
                    misc = EnsureDepartmentData("misc", json.decode(v.misc)),
                }, true)
            end
            CreateThread(function()
                Wait(1000)
                for _, player in pairs(GetPlayers()) do
                    EnsurePlayerDuty(tonumber(player), true, true)
                end
            end)
        end)
    end)
end)