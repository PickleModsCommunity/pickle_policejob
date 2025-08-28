lib.callback.register("pickle_policejob:fines:view", function(source, targetId)
    local fines = MySQL.query.await("SELECT * FROM pickle_police_fines WHERE identifier = ? ORDER BY time DESC", {GetIdentifier(targetId)})
    for i=1, #fines do
        
        fines[i].departmentLabel = GetDepartment(fines[i].departmentId).label
        fines[i].datetime = GetFormattedDate(math.floor(fines[i].time / 1000))
    end
    return {
        name = GetPlayerCharacterName(targetId),
        fines = fines
    }
end)

RegisterNetEvent("pickle_policejob:fines:payFine", function(fineId)
    local source = source
    local fine = MySQL.query.await("SELECT * FROM pickle_police_fines WHERE id = ?", {fineId})
    if not fine or #fine == 0 then return ShowNotification(source, _L("fine_not_found")) end
    fine = fine[1]
    local cash = GetMoney(source, "cash")
    local bank = GetMoney(source, "bank")
    if bank < fine.amount and cash < fine.amount then return ShowNotification(source, _L("fine_not_enough_money")) end
    if bank >= fine.amount then
        RemoveMoney(source, fine.amount, "bank")
    else
        RemoveMoney(source, fine.amount, "cash")
    end
    AddDepartmentMoney(fine.departmentId, fine.amount)
    MySQL.query("DELETE FROM pickle_police_fines WHERE id = ?", {fineId})
    ShowNotification(source, _L("fine_paid", NumberWithCommas(fine.amount)))
    Config.Integrations.fines.onFinePaid(fineId, source, fine.issuingIdentifier, fine.title, fine.description, fine.amount)
end)

RegisterNetEvent("pickle_policejob:fines:removeFine", function(fineId)
    local source = source
    local departmentId, member = GetPlayerDepartment(source)
    if not departmentId then return ShowNotification(source, _L("not_in_department")) end
    local rank, rankIndex = GetDepartmentRank(departmentId, member.rankId)
    if not rank then return ShowNotification(source, _L("fine_no_permission")) end
    local fine = MySQL.query.await("SELECT * FROM pickle_police_fines WHERE id = ?", {fineId})
    if not fine or #fine == 0 then return ShowNotification(source, _L("fine_not_found")) end
    fine = fine[1]
    if fine.issuingIdentifier ~= GetIdentifier(source) and rankIndex > 1 then return ShowNotification(source, _L("fine_no_permission")) end
    MySQL.query("DELETE FROM pickle_police_fines WHERE id = ?", {fineId})
    ShowNotification(source, _L("fine_removed", NumberWithCommas(fine.amount)))
    Config.Integrations.fines.onFineRemoved(fineId, source, fine.issuingIdentifier, fine.title, fine.description, fine.amount)
end)

RegisterNetEvent("pickle_policejob:fines:createFine", function(targetId, amount, title, description)
    local source = source
    if not IsPlayerOnDuty(source) then return ShowNotification(source, _L("not_on_duty")) end
    if not amount or amount < 1 or amount > Config.Fines.maxFineAmount then return ShowNotification(source, _L("invalid_fine_amount")) end
    if not title then return ShowNotification(source, _L("invalid_fine_title")) end
    if not description then return ShowNotification(source, _L("invalid_fine_description")) end
    local departmentId = GetPlayerDepartment(source)
    local fineId = MySQL.insert.await("INSERT INTO pickle_police_fines (identifier, issuingIdentifier, issuingName, departmentId, amount, title, description) VALUES (?, ?, ?, ?, ?, ?, ?)", {GetIdentifier(targetId), GetIdentifier(source), GetPlayerCharacterName(source), departmentId, amount, title, description})
    ShowNotification(targetId, _L("fined_victim", NumberWithCommas(amount), title, Config.Fines.viewFinesCommand))
    ShowNotification(source, _L("fined_issuer", GetPlayerCharacterName(targetId), NumberWithCommas(amount)))
    Config.Integrations.fines.onFineIssued(fineId, source, targetId, title, description, amount)
end)

MySQL.ready(function()
    MySQL.query("CREATE TABLE IF NOT EXISTS pickle_police_fines (id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(255), issuingIdentifier VARCHAR(255), issuingName VARCHAR(255), departmentId INT, amount INT, title VARCHAR(255), description TEXT, time DATETIME DEFAULT CURRENT_TIMESTAMP)")
end)