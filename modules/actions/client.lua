local Handcuffs = nil
local IsHandcuffed = false
local IsDragging = nil
local IsMenuOpen = false

function IsAnythingEquipped()
    return Handcuffs ~= nil
end

function GetEntityPlayer(entity)
    if GetEntityType(entity) ~= 1 then return false end
    local activePlayers = GetActivePlayers()
    for _, player in ipairs(activePlayers) do
        if GetPlayerPed(player) == entity then
            return player
        end
    end
    return nil
end

function EquipHandcuffs()
    if IsAnythingEquipped() then return ShowNotification(_L("already_equipped")) end
    ShowNotification(_L("equipped_handcuffs"))
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    Handcuffs = {}
    Handcuffs.prop = CreateProp(`m24_1_prop_m41_handcuffs_01a`, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(Handcuffs.prop, ped, GetPedBoneIndex(ped, 57005), 0.22, -0.05, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    CreateThread(function()
        local spriteDict, sprite = "darts", "dart_reticules"
        while Handcuffs do
            local ped = PlayerPedId()
            local _, weaponHash = GetCurrentPedWeapon(ped, false)
            if weaponHash ~= `WEAPON_UNARMED` then
                UnequipHandcuffs()
                return
            end
            if IsControlJustPressed(0, 202) then
                UnequipHandcuffs()
                return
            end
            RequestStreamedTextureDict(spriteDict, false)
            DisableControlAction(0, 24, true) -- Left click
            DisableControlAction(0, 25, true) -- Right click
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            local hit, hitCoords, entity = GetDirectionCoords()
            local hasTarget = false
            local targetPlayer = GetEntityPlayer(entity)
            if hit and targetPlayer and #(GetEntityCoords(ped) - hitCoords) < 1.5 then
                hasTarget = true
                local cuffStyle = nil
                if IsDisabledControlJustPressed(0, 24) then
                    cuffStyle = "back"
                elseif IsDisabledControlJustPressed(0, 25) then
                    cuffStyle = "front"
                end
                if cuffStyle then
                    TriggerServerEvent("pickle_policejob:actions:detainment", GetPlayerServerId(targetPlayer), {
                        eventType = "toggleHandcuffs",
                        cuffStyle = cuffStyle,

                    })
                end
            end
            DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, (hasTarget and 127 or 255), (hasTarget and 127 or 255), 255, 255)
            Wait(0)
        end
    end)
end

function UnequipHandcuffs()
    if not Handcuffs then return end
    DeleteEntity(Handcuffs.prop)
    Handcuffs = nil
end

function UnequipCurrentActions()
    UnequipHandcuffs()
end

function RemoveHandcuffs()
    if not IsHandcuffed then return end
    print("Removing handcuffs", IsHandcuffed.prop)
    DeleteEntity(IsHandcuffed.prop)
    IsHandcuffed = nil
end

function GetClosestPlayer()
    local ped = PlayerPedId()
    local closestPlayer = nil
    local closestDistance = 2.5
    for _, player in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(player)
        if playerPed ~= ped then
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - GetEntityCoords(ped))
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer, closestDistance
end

function OpenPoliceActionsMenu()
    if IsMenuOpen then return end
    local menuId = "pickle_policejob:actions:menu"
    local options = {
        {
            title = _L("actions_handcuffs"),
            description = _L("actions_handcuffs_description"),
            icon = "handcuffs",
            onSelect = function()
                EquipHandcuffs()
            end,
        },
        {
            title = _L("actions_drag"),
            description = _L("actions_drag_description"),
            icon = "drag",
            onSelect = function()
                local targetPlayer = GetClosestPlayer()
                if not targetPlayer then return end
                TriggerServerEvent("pickle_policejob:actions:detainment", GetPlayerServerId(targetPlayer), {
                    eventType = "toggleDrag",
                })
            end,
        }
    }
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

RegisterCommand("policeactions", function()
    OpenPoliceActionsMenu()
end)

RegisterKeyMapping("policeactions", "Police Actions", "keyboard", "F6")

RegisterNetEvent("pickle_policejob:actions:detainment", function(data)
    local source = GetPlayerServerId(PlayerId())
    if data.eventType == "toggleHandcuffs" then
        if data.cuffed then
            if data.target == source then
                UnequipCurrentActions()
                IsHandcuffed = {}
                local ped = PlayerPedId()
                local targetPed = GetPlayerPed(GetPlayerFromServerId(data.source))
                local targetOffset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 1.0, -1.0)
                SetEntityCoordsNoOffset(ped, targetOffset.x, targetOffset.y, targetOffset.z + 0.5, 0)
                SetEntityHeading(ped, data.heading)
                SetEnableHandcuffs(ped, true)
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) -- unarm player
                PlayAnim(ped, "mp_arrest_paired", "crook_p2_back_left", 8.0, -8.0, 5500, 33, 1.0, false, false, false)
                SetTimeout(5000, function()
                    if not IsHandcuffed then return end
                    IsHandcuffed.prop = CreateProp(`ba_prop_battle_cuffs`, targetOffset.x, targetOffset.y, targetOffset.z + 0.5, true, true, false)
                    local boneIndex = GetPedBoneIndex(ped, 60309)
                    local coords, rot = vector3(-0.035, 0.06, 0.04), vector3(265.25, 153.30, 81.12)
                    AttachEntityToEntity(IsHandcuffed.prop, ped, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, true, false, false, false, 0, true)
                    CreateThread(function()
                        while IsHandcuffed do
                            local ped = PlayerPedId()
                            if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) then
                                ClearPedTasks(ped)
                                PlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
                            end
                            DisableControlAction(0, 22, true) 
                            DisableControlAction(0, 23, true) 
                            DisableControlAction(0, 24, true)
                            DisableControlAction(0, 25, true) 
                            DisableControlAction(0, 30, true) 
                            DisableControlAction(0, 31, true) 
                            DisableControlAction(0, 32, true) 
                            DisableControlAction(0, 34, true) 
                            DisableControlAction(0, 36, true) 
                            DisableControlAction(0, 44, true) 
                            DisableControlAction(0, 45, true) 
                            DisableControlAction(0, 47, true) 
                            DisableControlAction(0, 75, true)  
                            DisableControlAction(0, 140, true) 
                            DisableControlAction(0, 141, true) 
                            DisableControlAction(0, 142, true) 
                            DisableControlAction(0, 143, true) 
                            DisableControlAction(0, 257, true) 
                            DisableControlAction(0, 263, true) 
                            DisableControlAction(0, 264, true) 
                            DisableControlAction(0, 289, true) 
                            Wait(0)
                        end
                        local ped = PlayerPedId()
                        ClearPedTasksImmediately(ped)
                        SetEnableHandcuffs(ped, false)
                    end)
                end)
            elseif data.source == source then
                UnequipCurrentActions()
                local ped = PlayerPedId()
                FreezeEntityPosition(ped, true)
                PlayAnim(ped, "mp_arrest_paired", "cop_p2_back_left", 8.0, -8,-1, 2, 0, 0, 0, 0)
                SetTimeout(3800, function()
                    ClearPedTasks(ped)
                    FreezeEntityPosition(ped, false)
                    ShowNotification(_L("player_detained"))
                end)
            end
        else
            if data.target == source then
                UnequipCurrentActions()
                local ped = PlayerPedId()
                Wait(4500)
                RemoveHandcuffs()
            elseif data.source == source then
                UnequipCurrentActions()
                local ped = PlayerPedId()
                PlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
                Wait(5500)
                ClearPedTasks(ped)
            end
        end
    elseif data.eventType == "toggleDrag" then
        local playerPed = PlayerPedId()
        local serverId = GetPlayerServerId(PlayerId())
        if data.dragged then
            if data.source == serverId then
                IsDragging = {
                    target = data.target,
                }
                CreateThread(function()
                    local animLoop = true
                    HIDE_INTERACTIONS = true
                    while IsDragging and IsDragging.target == data.target do
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        if GetEntityHealth(playerPed) <= 0 then
                            TriggerServerEvent("pickle_policejob:actions:detainment", data.target, {
                                target = data.target,
                                eventType = "stopDrag",
                            })
                            return
                        end
                        if animLoop and not IsEntityPlayingAnim(playerPed, 'missfbi4prepp1', 'idle', 3) then 
                            PlayAnim(playerPed, 'missfbi4prepp1', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
                            animLoop = false
                            SetTimeout(1000, function()
                                animLoop = true
                            end)
                        end
                        Wait(0)
                    end
                    ClearPedTasks(playerPed)
                    HIDE_INTERACTIONS = false
                end)
            end
            if data.target == serverId then
                IsDragging = {
                    source = data.source,
                }
                CreateThread(function()
                    local ped = PlayerPedId()
                    local sourcePed = GetPlayerPed(GetPlayerFromServerId(data.source))
                    local boneIndex = GetPedBoneIndex(sourcePed, 0x60F2)
                    local coords, rot = vector3(-0.25, 0.24, -0.5), vector3(0.0, 90.0, 0.0)
                    AttachEntityToEntity(ped, sourcePed, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 0, 0, 0, 1, 2, 1)
                    local moving = false
                    while IsDragging and IsDragging.source == data.source do
                        sourcePed = GetPlayerPed(GetPlayerFromServerId(data.source))
                        ped = PlayerPedId()
                        -- if GetEntityHealth(ped) <= 0 then
                        --     TriggerServerEvent("pickle_policejob:actions:detainment", data.target, {
                        --         eventType = "stopDrag",
                        --     })
                        --     return
                        -- end
                        if IsPedWalking(sourcePed) then
                            if not IsEntityPlayingAnim(ped, 'move_action@generic@core', 'walk', 3) then 
                                moving = true
                                PlayAnim(ped, 'move_action@generic@core', 'walk', 8.0, -8.0, -1, 1, 0, false, false, false)
                            end
                        elseif IsPedSprinting(sourcePed) or IsPedRunning(sourcePed) then
                            if not IsEntityPlayingAnim(ped, 'move_action@generic@core', 'run', 3) then 
                                moving = true
                                PlayAnim(ped, 'move_action@generic@core', 'run', 8.0, -8.0, -1, 1, 0, false, false, false)
                            end
                        elseif moving then
                            moving = false
                            ClearPedTasks(ped)
                            PlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
                        end
                        Wait(0)
                    end
                    ClearPedTasks(ped)
                    DetachEntity(ped, true, true)
                end)
            end
        else
            print(data.source, data.target, serverId)
            if data.source == serverId then
                IsDragging = nil
            elseif data.target == serverId then
                IsDragging = nil
            end
            print(IsDragging)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    EquipHandcuffs()
end)

RegisterCommand("handcuffs", function()
    EquipHandcuffs()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        UnequipCurrentActions()
        RemoveHandcuffs()
    end
end)