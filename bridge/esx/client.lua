if GetResourceState('es_extended') ~= 'started' then return end

ESX = exports.es_extended:getSharedObject()

function ShowNotification(text)
	ESX.ShowNotification(text)
end

function CanAccessGroup(data)
    if not data then return true end
    local pdata = ESX.GetPlayerData()
    for k,v in pairs(data) do 
        if (pdata.job.name == k and pdata.job.grade >= v) then return true end
    end
    return false
end 

function GetPlayersInArea(coords, radius)
    local coords = coords or GetEntityCoords(PlayerPedId())
    local radius = radius or 3.0
    local list = ESX.Game.GetPlayersInArea(coords, radius)
    local players = {}
    for _, player in pairs(list) do 
        if player ~= PlayerId() then
            players[#players + 1] = player
        end
    end

    return players
end

function ResetClothes()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        TriggerEvent('skinchanger:loadSkin', skin)
        TriggerEvent('esx:restoreLoadout')
    end)
end

function Revive()
    TriggerEvent("esx_basicneeds:resetStatus")
    TriggerEvent("esx_ambulancejob:revive")
end

function Kill()
    SetEntityHealth(PlayerPedId(), 0)
end

RegisterNetEvent(GetCurrentResourceName()..":showNotification", function(text)
    ShowNotification(text)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
    TriggerServerEvent("pickle_policejob:initializePlayer")
end)

function ToggleOutfit(onduty)
    if onduty then 
        local outfits = Config.BountyHunters.outfits
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
            local gender = skin.sex
            local outfit = gender == 1 and outfits.female or outfits.male
            if not outfit then return end
            TriggerEvent('skinchanger:loadClothes', skin, outfit)
        end)
    else
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
            local gender = skin.sex
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    end
end

function OpenNearbyInventory()
    Config.Integrations.inventory.OpenNearbyInventory()
end

-- Inventory Fallback

CreateThread(function()
    Wait(100)
    
    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.

    Inventory = {}

    Inventory.Items = {}
    
    Inventory.Ready = false
    
    Inventory.OpenStash = function(stash, isPersonalStash)
        ShowNotification("Your inventory does not support stashes, please make a ticket at https://discord.gg/picklemods")
    end

    RegisterNetEvent("pickle_policejob:setupInventory", function(items)
        Inventory.Items = items
        Inventory.Ready = true
    end)
    
    RegisterNetEvent("pickle_policejob:updateInventory", function(inventory) 
        -- RefreshInventory(inventory)
    end)
end)