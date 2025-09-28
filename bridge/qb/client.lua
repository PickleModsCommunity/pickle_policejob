if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function ShowNotification(text)
	QBCore.Functions.Notify(text)
end

function CanAccessGroup(data)
    if not data then return true end
    local pdata = QBCore.Functions.GetPlayerData()
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade.level >= v) then return true end
    end
    return false
end 

function GetPlayersInArea(coords, radius)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 3.0
    local list = QBCore.Functions.GetPlayersFromCoords(coords, radius)
    local players = {}
    for _, player in pairs(list) do 
        if player ~= PlayerId() then
            players[#players + 1] = player
        end
    end
    return players
end


function ToggleOutfit(onduty)
    if onduty then 
        local outfits = Config.BountyHunters.outfits
        local gender = QBCore.Functions.GetPlayerData().charinfo.gender
        local outfit = gender == 1 and outfits.female or outfits.male
        if not outfit then return end 
        TriggerEvent('qb-clothing:client:loadOutfit', {outfitData = outfit})
    else
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
    end
end

function ResetClothes()
    TriggerServerEvent("qb-clothes:loadPlayerSkin")
end

function Revive()
    TriggerEvent("hospital:client:Revive")
    TriggerServerEvent("hospital:server:resetHungerThirst")
end

function Kill()
    SetEntityHealth(PlayerPedId(), 0)
end

RegisterNetEvent('police:client:SendToJail', function(time)
    TriggerEvent("prison:client:Enter", time)
end)

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent("pickle_policejob:initializePlayer")
end)

-- QB Events & Alcohol Status Support

local CurrentStatus
local Statuses = {
    ["alcohol"] = _L("alcohol_status"),
    ["heavyalcohol"] = _L("heavy_alcohol_status"),
}

RegisterNetEvent("evidence:client:SetStatus", function(statusId, time)
    if not Statuses[statusId] then return end -- If the status is not in the list, return.
    if time > 0 then
        if not CurrentStatus then CurrentStatus = {} end
        if (CurrentStatus[statusId] == nil) or (CurrentStatus[statusId] and CurrentStatus[statusId].time < 20) then
            CurrentStatus[statusId] = {text = Statuses[statusId], time = time}
            ShowNotification(CurrentStatus[statusId].text)
        end
    else
        CurrentStatus[statusId] = nil
    end
    TriggerServerEvent("evidence:server:UpdateStatus", CurrentStatus)
end)

RegisterNetEvent("police:client:EscortPlayer", function()
    local targetPlayer = GetClosestPlayer()
    if not targetPlayer then return end
    TriggerServerEvent("pickle_policejob:actions:detainment", GetPlayerServerId(targetPlayer), {
        eventType = "toggleDrag",
    })
end)

RegisterNetEvent("police:client:SearchPlayer", function()
    OpenNearbyInventory()
end)

RegisterNetEvent("police:client:JailPlayer", function()
    if Config.Integrations.jail.openJailMenu() then return end
    OpenPoliceJailMenu()
end)

RegisterNetEvent("police:client:SetPlayerOutVehicle", function()
    local targetPlayer = GetClosestPlayer()
    if not targetPlayer then return ShowNotification(_L("no_player_nearby")) end
    local targetVehicle = GetNearestVehicle()
    if not targetVehicle then return ShowNotification(_L("no_vehicle_nearby")) end
    local seatId = nil
    if not IsPedInVehicle(GetPlayerPed(targetPlayer), targetVehicle, false) then
        local maxPassengers = GetVehicleMaxNumberOfPassengers(targetVehicle)
        local openSeats = {}
        for i=1, maxPassengers - 1 do
            local result = GetPedInVehicleSeat(targetVehicle, i)
            if not result or result == 0 then
                table.insert(openSeats, i)
            end
        end
        if #openSeats == 0 then
            ShowNotification(_L("vehicle_full"))
            return
        end
        seatId = openSeats[1]
    end
    TriggerServerEvent("pickle_policejob:actions:detainment", GetPlayerServerId(targetPlayer), {
        eventType = "toggleVehicleSeat",
        netId = VehToNet(targetVehicle),
        seatId = seatId,
    })
end)

RegisterNetEvent("police:client:SeizeDriverLicense", function()
    local targetPlayer = GetClosestPlayer()
    if not targetPlayer then return ShowNotification(_L("no_player_nearby")) end
    TriggerServerEvent("police:server:SeizeDriverLicense", GetPlayerServerId(targetPlayer))
end)

CreateThread(function()
    local refreshRate = 10
    while true do
        if LocalPlayer.state.isLoggedIn then
            if CurrentStatus then
                local updatedStatus = false
                for k, v in pairs(CurrentStatus) do
                    updatedStatus = true
                    CurrentStatus[k].time = (CurrentStatus[k].time > 0 and (CurrentStatus[k].time - 10) or 0)
                end
                if updatedStatus then
                    TriggerServerEvent('evidence:server:UpdateStatus', CurrentStatus)
                end
            end
        end
        Wait(refreshRate * 1000)
    end
end)

-- Search Player

function OpenNearbyInventory()
    local closestPlayer = GetClosestPlayer()
    if not closestPlayer then return ShowNotification(_L("no_player_nearby")) end
    TriggerServerEvent("pickle_policejob:searchPlayer", GetPlayerServerId(closestPlayer))
    Config.Integrations.inventory.OpenNearbyInventory()
end

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.

    Config.ImageDirectory = "nui://qb-inventory/html/images/"

    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false

    Inventory.OpenStash = function(stash, isPersonalStash)
        TriggerServerEvent("pickle_policejob:openStash", stash, isPersonalStash)
    end

    RegisterNetEvent("pickle_policejob:setupInventory", function(items)
        Inventory.Items = items
        Inventory.Ready = true
    end)
    
    RegisterNetEvent("pickle_policejob:updateInventory", function(inventory) 
        -- RefreshInventory(inventory)
    end)
end)