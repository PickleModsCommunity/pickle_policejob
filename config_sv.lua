ConfigSV = {}
ConfigSV.Webhooks = {
    ["computer"] = { 
        url = "WEBHOOK_URL",
        title = "Computer Terminal Update",
        fields = {
            { name = "Player", value = "player", inline = false },
            { name = "Department", value = "department", inline = false },
            { name = "Update Type", value = "updateType", inline = false },
            { name = "Data", value = "data", inline = false },
        }
    },
    ["management"] = {
        url = "WEBHOOK_URL",
        title = "Management Update",
        fields = {
            { name = "Player", value = "player", inline = false },
            { name = "Department", value = "department", inline = false },
            { name = "Action", value = "action", inline = false },
            { name = "Data", value = "data", inline = false },
        }
    },
}

----------------------------------------------------
-- ONLY CHANGE BELOW IF YOU KNOW WHAT YOU ARE DOING!
----------------------------------------------------

ConfigSV.WebhookHandler = function(webhookId, fields)
    local webhook = ConfigSV.Webhooks[webhookId]
    if webhook then
        if webhook.url == "DISCORD_WEBHOOK_URL" then return end -- DONT CHANGE IT WILL BREAK THE WEBHOOKS
        local embed = {
            {
                ["title"] = webhook.title,
                ["color"] = 16711680,
                ["fields"] = {},
                ["footer"] = {
                    ["text"] = "Pickle's Police Job - " .. os.date("%c"),
                },
            }
        }
        for i=1, #webhook.fields do
            local field = webhook.fields[i]
            table.insert(embed[1].fields, {
                ["name"] = field.name,
                ["value"] = fields[field.value],
                ["inline"] = field.inline or false
            })
        end
        PerformHttpRequest(webhook.url, function(err, text, headers)
        end, "POST", json.encode({embeds = embed}), {["Content-Type"] = "application/json"})
    end
end

ConfigSV.AddOwnedVehicle = function(source, model)
    if GetResourceState('es_extended') == 'started' then 
        -- ESX
        local xPlayer = ESX.GetPlayerFromId(source)
        local plate = ""
        local letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
        local numbers = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
        for i = 1, 3 do
            plate = plate .. letters[math.random(1, #letters)]
        end
        plate = plate .. " "
        for i = 1, 3 do
            plate = plate .. numbers[math.random(1, #numbers)]
        end
        MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle);", {
            ['@owner'] = xPlayer.identifier,
            ['@plate'] = plate,
            ['@vehicle'] = json.encode({
                plate = toupper(plate),
                model = joaat(model),
            }),
        })
        return plate
    else
        -- QB / QBX
        local xPlayer = QBCore.Functions.GetPlayer(tonumber(source))
        local plate = ""
        local letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
        local numbers = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
        for i = 1, 3 do
            plate = plate .. letters[math.random(1, #letters)]
        end
        plate = plate .. " "
        for i = 1, 3 do
            plate = plate .. numbers[math.random(1, #numbers)]
        end
        MySQL.Async.fetchAll('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, plate, garage, state) VALUES (@license, @citizenid, @vehicle, @hash, @plate, @garage, @state)',
        {
            ['@license'] = xPlayer.PlayerData.license,
            ['@citizenid'] = xPlayer.PlayerData.citizenid,
            ['@vehicle'] = model,
            ['@hash'] = joaat(model),
            ['@plate'] = toupper(plate),
            ['@garage'] = "pillboxgarage",
            ['@state'] = 0
        })
        return plate
    end
end