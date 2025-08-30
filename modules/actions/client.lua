local Handcuffs = nil
local IsCurrentlyHandcuffed = false
local IsDragging = nil
local IsMenuOpen = false
local EquippedStabSticks = nil
local EquippedBreathalyzer = nil
local EquippedFingerprintScanner = nil
local StabSticks = {}
local RenderedStabSticks = {}
local ObjectPlacement = {}
local ObjectPlacementInteractions = {}

function IsAnythingEquipped()
    return Handcuffs ~= nil or EquippedStabSticks ~= nil or EquippedBreathalyzer ~= nil or EquippedFingerprintScanner ~= nil
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

function IsHandcuffed()
    return IsCurrentlyHandcuffed
end

exports("IsHandcuffed", IsHandcuffed)

function UnequipCurrentActions()
    UnequipHandcuffs()
    UnequipStabSticks()
    UnequipBreathalyzer()
    UnequipFingerprintScanner()
    if Config.Evidence.enabled then
        StopCameraLoop()
    end
end

function RemoveHandcuffs()
    if not IsCurrentlyHandcuffed then return end
    DeleteEntity(IsCurrentlyHandcuffed.prop)
    IsCurrentlyHandcuffed = nil
end

-- Stab Sticks

function UnrenderStackedStabSticks()
    if not EquippedStabSticks then return end
    for _, prop in ipairs(EquippedStabSticks.lengthProps) do
        DeleteEntity(prop)
    end
    EquippedStabSticks.lengthProps = {}
end

function RenderStackedStabSticks()
    if not EquippedStabSticks then return end
    UnrenderStackedStabSticks()
    if EquippedStabSticks.length == 1 then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local boneIndex = GetPedBoneIndex(ped, 0x60F2)
    for i=1, EquippedStabSticks.length - 1 do
        local prop = CreateProp(`npds_p_pb`, coords.x, coords.y, coords.z, true, true, false)
        local propCoords = vector3(-2.5 * i, 0.0, 0.0)
        local rot = vector3(0.0, 0.0, 0.0)
        table.insert(EquippedStabSticks.lengthProps, prop)
        AttachEntityToEntity(prop, EquippedStabSticks.prop, boneIndex, propCoords.x, propCoords.y, propCoords.z, rot.x, rot.y, rot.z, 0, 0, 0, 0, 2, 1)
    end
end

function EquipStabSticks(amount)
    if not IsPlayerOnDuty() then return ShowNotification(_L("not_on_duty")) end
    if IsAnythingEquipped() then return ShowNotification(_L("already_equipped")) end
    ShowNotification(_L("equipped_stab_sticks"))
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local maxStickLength = Config.StabSticks.maxLength
    EquippedStabSticks = {}
    EquippedStabSticks.lengthProps = {}
    EquippedStabSticks.prop = CreateProp(`npds_p_pbr_2`, coords.x, coords.y, coords.z, true, true, false)
    EquippedStabSticks.length = amount or 1
    local boneIndex = GetPedBoneIndex(ped, 0x60F2)
    local coords, rot = vector3(-0.85, -2.45, -0.55), vector3(90.0, 95.0, 0.0)
    AttachEntityToEntity(EquippedStabSticks.prop, ped, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, 0, 0, 0, 0, 2, 1)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RenderStackedStabSticks()
    CreateThread(function()
        local animLoop = true
        HIDE_INTERACTIONS = true
        while EquippedStabSticks do
            local playerPed = PlayerPedId()
            DisableControlAction(0, 37, true) -- Weapon wheel
            ShowInteractText(_L("stab_sticks_controls", EquippedStabSticks.length))
            if IsDisabledControlPressed(0, 15) and EquippedStabSticks.length < maxStickLength then -- Scroll up
                EquippedStabSticks.length = EquippedStabSticks.length + 1
                RenderStackedStabSticks()
            elseif IsDisabledControlPressed(0, 14) and EquippedStabSticks.length > 1 then -- Scroll down
                EquippedStabSticks.length = EquippedStabSticks.length - 1
                RenderStackedStabSticks()
            elseif IsControlJustPressed(0, 202) then -- ESC
                UnequipStabSticks()
            elseif IsControlJustPressed(1, 51) then -- E
                DetachEntity(EquippedStabSticks.prop, true, true)
                local coords = GetEntityCoords(EquippedStabSticks.prop)
                local rot = GetEntityRotation(EquippedStabSticks.prop)
                DeleteEntity(EquippedStabSticks.prop)
                local _, groundZ = GetGroundZExcludingObjectsFor_3dCoord(coords.x, coords.y, coords.z + 1000.0)
                EquippedStabSticks.prop = CreateProp(`npds_p_pb`, coords.x, coords.y, groundZ + 0.1, true, true, false)
                SetEntityRotation(EquippedStabSticks.prop, 0.0, 0.0, rot.z, 2, true)
                PlaceObjectOnGroundProperly(EquippedStabSticks.prop)
                FreezeEntityPosition(EquippedStabSticks.prop, true)
                for i=1, #EquippedStabSticks.lengthProps do
                    local prop = EquippedStabSticks.lengthProps[i]
                    DetachEntity(prop, true, true)
                    local coords = GetEntityCoords(prop)
                    local _, groundZ = GetGroundZExcludingObjectsFor_3dCoord(coords.x, coords.y, coords.z + 1000.0)
                    SetEntityCoords(prop, coords.x, coords.y, groundZ + 0.1)
                    SetEntityRotation(prop, 0.0, 0.0, rot.z, 2, true)
                    PlaceObjectOnGroundProperly(prop)
                    FreezeEntityPosition(prop, true)
                end
                local sticks = {
                    {
                        coords = GetEntityCoords(EquippedStabSticks.prop),
                        rotation = GetEntityRotation(EquippedStabSticks.prop),
                    }
                }
                for i=1, #EquippedStabSticks.lengthProps do
                    table.insert(sticks, {
                        coords = GetEntityCoords(EquippedStabSticks.lengthProps[i]),
                        rotation = GetEntityRotation(EquippedStabSticks.lengthProps[i]),
                    })
                end
                UnequipStabSticks()
                TriggerServerEvent("pickle_policejob:actions:placeStabSticks", sticks)
                return
            end
            if GetEntityHealth(playerPed) <= 0 then
                UnequipCurrentActions()
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

function UnequipStabSticks()
    if not EquippedStabSticks then return end
    DeleteEntity(EquippedStabSticks.prop)
    UnrenderStackedStabSticks()
    EquippedStabSticks = nil
    SetTimeout(10, function()
        ClearPedTasks(PlayerPedId())
    end)
end 

function IsStabStickRendered(id)
    return RenderedStabSticks[id]
end

function StabStickRenderProcess(id)
    if not StabSticks[id] then return end
    local mainNode = StabSticks[id].sticks[1]
    local coords = mainNode.coords
    local pcoords = GetEntityCoords(PlayerPedId())
    local distance = #(coords - pcoords)
    if IsStabStickRendered(id) then 
        if distance > Config.StabSticks.renderDistance then
            UnrenderStabSticks(id)
        end
    elseif distance < Config.StabSticks.renderDistance then
        RenderStabSticks(id)
    end
    return IsStabStickRendered(id), distance
end

function RenderStabSticks(id)
    if not StabSticks[id] then return end
    if RenderedStabSticks[id] then 
        UnrenderStabSticks(id)
    end
    RenderedStabSticks[id] = {}
    for _, stick in ipairs(StabSticks[id].sticks) do
        local prop = CreateProp(`npds_p_pb`, stick.coords.x, stick.coords.y, stick.coords.z, false, false, false)
        SetEntityRotation(prop, stick.rotation.x, stick.rotation.y, stick.rotation.z, 2, true)
        FreezeEntityPosition(prop, true)
        PlaceObjectOnGroundProperly(prop)
        table.insert(RenderedStabSticks[id], prop)
    end
end

function UnrenderStabSticks(id)
    if not RenderedStabSticks[id] then return end
    for _, prop in ipairs(RenderedStabSticks[id]) do
        DeleteEntity(prop)
    end
    RenderedStabSticks[id] = nil
end

RegisterNetEvent("pickle_policejob:actions:createStabSticks", function(id, sticks)
    StabSticks[id] = sticks
    StabStickRenderProcess(id)
end)

RegisterNetEvent("pickle_policejob:actions:deleteStabSticks", function(id)
    UnrenderStabSticks(id)
    StabSticks[id] = nil
end)

function StabStickGameProcess(id)
    if not StabSticks[id] then return end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local targetableBones = {}
    if not DoesEntityExist(vehicle) then 
        if not Config.UseTarget and IsPlayerOnDuty() then
            local closestStick = nil
            local closestDistance = 100.0
            for _, stick in ipairs(StabSticks[id].sticks) do
                local distance = #(stick.coords - GetEntityCoords(PlayerPedId()))
                if distance < closestDistance then
                    closestStick = stick
                    closestDistance = distance
                end
            end
            if closestDistance < 2.0 then
                ShowInteractText(_L("stab_sticks_pickup"))
                if IsControlJustPressed(1, 51) then
                    TriggerServerEvent("pickle_policejob:actions:deleteStabSticks", id)
                    EquipStabSticks(#StabSticks[id].sticks)
                end
                return true
            end
        end
    else
        for _, stick in ipairs(StabSticks[id].sticks) do
            local WHEEL_BONES = {"wheel_lf", "wheel_rf", "wheel_lm", "wheel_rm", "wheel_lr", "wheel_rr"}
            for wheelIndex, bone in ipairs(WHEEL_BONES) do
                local boneIndex = GetEntityBoneIndexByName(vehicle, bone)
                local coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                local distance = #(coords - stick.coords)
                if distance < 1.0 then
                    table.insert(targetableBones, {bone = bone, wheelIndex = wheelIndex - 1})
                end
            end
        end
        if #targetableBones > 0 then
            for i=1, #targetableBones do
                local tireHealth = GetTyreHealth(vehicle, targetableBones[i].wheelIndex)
                if tireHealth >= 1000 then
                    SetVehicleTyreBurst(vehicle, targetableBones[i].wheelIndex, false, Config.StabSticks.burstDamage)
                end
            end
        end
        return true
    end
end

-- Breathalyzer

function EquipBreathalyzer()
    if not IsPlayerOnDuty() then return ShowNotification(_L("not_on_duty")) end
    if IsAnythingEquipped() then return ShowNotification(_L("already_equipped")) end
    ShowNotification(_L("equipped_breathalyzer"))
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    EquippedBreathalyzer = {}
    EquippedBreathalyzer.prop = CreateProp(`xm3_prop_xm3_vape_01a`, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local coords, rot = vector3(0.1, 0.08, 0.0), vector3(-0.0, 0.0, 0.0)
    AttachEntityToEntity(EquippedBreathalyzer.prop, ped, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, true, false, false, false, 0, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    CreateThread(function()
        local spriteDict, sprite = "darts", "dart_reticules"
        local timer
        while EquippedBreathalyzer do
            DisableControlAction(0, 24, true) -- Left click
            DisableControlAction(0, 25, true) -- Right click
            RequestStreamedTextureDict(spriteDict, false)
            if IsControlJustPressed(0, 202) then
                UnequipBreathalyzer()
            end
            local hit, hitCoords, entity = GetDirectionCoords()
            local hasTarget = false
            local targetPlayer = GetEntityPlayer(entity)
            if hit and targetPlayer and #(GetEntityCoords(ped) - hitCoords) < 1.5 then
                hasTarget = true
                if IsDisabledControlJustPressed(0, 24) then
                    if not timer then
                        PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 0)
                        timer = 200
                        CreateThread(function()
                            while timer ~= nil do
                                timer = timer - 1
                                if timer <= 0 then break end
                                Wait(0)
                            end
                            if timer and timer <= 0 then
                                PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 0)
                                Wait(150)
                                PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 0)
                                Wait(150)
                                PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 0)
                                Wait(150)
                                lib.callback("pickle_policejob:evidence:getBAC", false, function(result)
                                    local alert = lib.alertDialog({
                                        header = _L("breathalyzer_result", result),
                                        content = _L("breathalyzer_result_content"),
                                        centered = true,
                                        cancel = true
                                    })
                                    if alert == "confirm" then
                                        TriggerServerEvent("pickle_policejob:evidence:addBAC", GetPlayerServerId(targetPlayer), result)
                                    end
                                end, GetPlayerServerId(targetPlayer))
                            end
                            timer = nil
                        end)
                    end
                    local playerPed = PlayerPedId()
                    PlayAnim(playerPed, "molly@megaphone", "megaphone_clip", 2.0, -2.0, -1, 49, 0, false, false, false)
                    AttachEntityToEntity(EquippedBreathalyzer.prop, playerPed, boneIndex, coords.x + 0.05, coords.y - 0.06, coords.z - 0.015, rot.x + 45.0, rot.y + 45.0, rot.z - 90.0, true, false, false, false, 0, true)
                elseif IsDisabledControlJustReleased(0, 24) then
                    if timer then
                        timer = nil
                    end
                    local playerPed = PlayerPedId()
                    AttachEntityToEntity(EquippedBreathalyzer.prop, playerPed, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, true, false, false, false, 0, true)
                    ClearPedTasks(playerPed)
                end
            end
            DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, (hasTarget and 127 or 255), (hasTarget and 127 or 255), 255, 255)
            Wait(0)
        end
        ClearPedTasks(PlayerPedId())
    end)
end

function UnequipBreathalyzer()
    if not EquippedBreathalyzer then return end
    DeleteEntity(EquippedBreathalyzer.prop)
    EquippedBreathalyzer = nil
    SetTimeout(10, function()
        ClearPedTasks(PlayerPedId())
    end)
end

-- Fingerprint Scanner

function EquipFingerprintScanner()
    if not IsPlayerOnDuty() then return ShowNotification(_L("not_on_duty")) end
    if IsAnythingEquipped() then return ShowNotification(_L("already_equipped")) end
    ShowNotification(_L("equipped_fingerprint_scanner"))
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    EquippedFingerprintScanner = {}
    EquippedFingerprintScanner.entities = {} 
    table.insert(EquippedFingerprintScanner.entities, CreateProp(`prop_police_id_board`, coords.x, coords.y, coords.z, true, true, false))
    table.insert(EquippedFingerprintScanner.entities, CreateProp(`ch_prop_fingerprint_scanner_01e`, coords.x, coords.y, coords.z, true, true, false))
    local boneIndex = GetPedBoneIndex(ped, 58868)
    local coords, rot = vector3(0.12, 0.24, 0.0), vector3(5.0, 0.0, 70.0)
    AttachEntityToEntity(EquippedFingerprintScanner.entities[1], ped, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, true, false, false, false, 0, true)
    AttachEntityToEntity(EquippedFingerprintScanner.entities[2], EquippedFingerprintScanner.entities[1], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 0, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    PlayAnim(ped, "mp_character_creation@customise@male_a", "loop", 2.0, -2.0, -1, 49, 0, false, false, false)
    CreateThread(function()
        local spriteDict, sprite = "darts", "dart_reticules"
        while EquippedFingerprintScanner do
            DisableControlAction(0, 24, true) -- Left click
            DisableControlAction(0, 25, true) -- Right click
            RequestStreamedTextureDict(spriteDict, false)
            if IsControlJustPressed(0, 202) then
                UnequipFingerprintScanner()
            end
            local hit, hitCoords, entity = GetDirectionCoords()
            local hasTarget = false
            local targetPlayer = GetEntityPlayer(entity)
            if hit and targetPlayer and #(GetEntityCoords(ped) - hitCoords) < 1.5 then
                hasTarget = true
                if IsDisabledControlJustPressed(0, 24) then
                    TriggerServerEvent("pickle_policejob:actions:requestFingerprint", GetPlayerServerId(targetPlayer))
                end
            end
            DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, (hasTarget and 127 or 255), (hasTarget and 127 or 255), 255, 255)
            Wait(0)
        end
        ClearPedTasks(PlayerPedId())
    end)
end

RegisterNetEvent("pickle_policejob:actions:requestFingerprint", function(requestId, result, targetId)
    local serverId = GetPlayerServerId(PlayerId())
    if serverId ~= requestId then 
        local alert = lib.alertDialog({
            header = _L("fingerprint_scan_request"),
            content = _L("fingerprint_scan_request_content"),
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            TriggerServerEvent("pickle_policejob:actions:grantFingerprintConsent", requestId)
        end
    else
        local alert = lib.alertDialog({
            header = _L("fingerprint_scan_result", result),
            content = _L("fingerprint_scan_result_content"),
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            TriggerServerEvent("pickle_policejob:evidence:addFingerprint", targetId)
        end
    end
end)

function UnequipFingerprintScanner()
    if not EquippedFingerprintScanner then return end
    for _, entity in ipairs(EquippedFingerprintScanner.entities) do
        DeleteEntity(entity)
    end
    EquippedFingerprintScanner = nil
    SetTimeout(10, function()
        ClearPedTasks(PlayerPedId())
    end)
end

-- Jail

function OpenPoliceJailMenu()
    local players = GetPlayersInArea()
    local players_list = {}
    local prisons = {}
    for i=1, #players do
        local id = GetPlayerServerId(players[i])
        players_list[#players_list + 1] = {label = _L("jail_dialog_player", GetPlayerName(players[i]), id), value = id}
    end
    for k,v in pairs(Config.Prisons) do 
        prisons[#prisons + 1] = {label = v.label, value = k}
    end
    if #prisons < 1 or #players_list < 1 then return end
    local input = lib.inputDialog(_L("jail_dialog_title"), {
        {type = 'select', label = _L("jail_dialog_prisoner"), default = players_list[1].value, required = true, options = players_list},
        {type = 'number', label = _L("jail_dialog_sentence"), default = 1, required = true, min = 1, max = Config.Jail.maxJailTime},
    }) 
    if not input then return end
    TriggerServerEvent("pickle_policejob:actions:jailPlayer", input[1], input[2])
end

-- Misc

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

function GetNearestVehicle(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local pool = GetGamePool("CVehicle")
    local closestVehicle = nil
    local closestDistance = distance or 3.0
    for _, vehicle in ipairs(pool) do
        local distance = #(GetEntityCoords(vehicle) - coords)
        if distance < closestDistance and NetworkGetEntityIsNetworked(vehicle) then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end
    return closestVehicle
end

function OpenObjectPlacementMenu()
    local menuId = "pickle_policejob:actions:objectplacement"
    local options = {}
    for i=1, #Config.ObjectPlacement.props do
        table.insert(options, {
            title = Config.ObjectPlacement.props[i].label,
            description = _L("object_description", Config.ObjectPlacement.props[i].label),
            image = Config.ObjectPlacement.props[i].image,
            onSelect = function()
                local object = CreateProp(Config.ObjectPlacement.props[i].model, GetEntityCoords(PlayerPedId()), false, false, false)
                local result = StartGizmoEditor({
                    entity = object,
                })
                DeleteEntity(object)
                TriggerServerEvent("pickle_policejob:actions:placeObject", {
                    index = i,
                    coords = result.position,
                    rotation = result.rotation,
                })
                OpenObjectPlacementMenu()
            end,
        })
    end
    lib.registerContext({
        id = menuId,
        menu = "pickle_policejob:actions:menu",
        title = _L("actions_objects"),
        options = options,
        onExit = function()
            IsMenuOpen = false
        end,
    })
    lib.showContext(menuId)
end

function OpenIDCardMenu()
    local player = GetClosestPlayer()
    if not player then return ShowNotification(_L("no_player_nearby")) end
    local targetId = GetPlayerServerId(player)
    lib.callback("pickle_policejob:actions:getIDCard", false, function(result)
        if not result then return ShowNotification(_L("no_id_card")) end
        local menuId = "pickle_policejob:actions:idcard"
        local options = {
            {
                title = _L("id_card_name"),
                description = result.name,
                icon = Config.TargetIcons.id_card,
            },
            {
                title = _L("id_card_dob"),
                description = result.dob,
                icon = "fas fa-calendar-alt",
            },
            {
                title = _L("id_card_gender"),
                description = result.gender,
                icon = "fas fa-venus-mars",
            },
            {
                title = _L("id_card_job"),
                description = result.job,
                icon = "fas fa-briefcase",
            },
        }
        lib.registerContext({
            id = menuId,
            title = _L("actions_id_card"),
            options = options,
            onExit = function()
                SetTimeout(100, function()
                    OpenPoliceActionsMenu()
                end)
            end
        })
        lib.showContext(menuId)
    end, targetId)
end

function OpenVehicleInteractMenu()
    local vehicle = GetNearestVehicle()
    if not vehicle then return ShowNotification(_L("no_vehicle_nearby")) end
    lib.callback("pickle_policejob:actions:getVehicleInfo", false, function(result)
        if not vehicle then return ShowNotification(_L("no_vehicle_nearby")) end
        local menuId = "pickle_policejob:actions:vehicleinteract"
        local options = {
            {
                title = _L("vehicle_owner"),
                description = result.owner,
                icon = "fas fa-id-card",
            },
            {
                title = _L("vehicle_plate"),
                description = result.plate,
                icon = "fas fa-car",
            },
            {
                title = _L("vehicle_lockpick"),
                description = _L("vehicle_lockpick_description"),
                icon = "fas fa-lock",
                onSelect = function()
                    local ped = PlayerPedId()
                    PlayAnim(ped, "mini@repair", "fixing_a_ped", 1.0, -1.0, -1, 0, 0, false, false, false)
                    local success = lib.skillCheck({'easy', 'medium', 'medium', 'medium'}, {'w', 'a', 's', 'd'})
                    ClearPedTasks(ped)
                    if not success then
                        ShowNotification(_L("failed_lockpick"))
                        return OpenVehicleInteractMenu()
                    end
                    TriggerServerEvent("pickle_policejob:actions:lockpickVehicle", VehToNet(vehicle))
                end,
            },
            {
                title = _L("vehicle_impound"),
                description = _L("vehicle_impound_description"),
                icon = "fas fa-shuttle-van",
                onSelect = function()
                    local ped = PlayerPedId()
                    PlayAnim(ped, "mini@repair", "fixing_a_ped", 1.0, -1.0, -1, 0, 0, false, false, false)
                    lib.progressCircle({
                        duration = 5000,
                        label = _L("vehicle_impound_progress"),
                        disable = {
                            move = true,
                        }
                    })
                    ClearPedTasks(ped)
                    TriggerServerEvent("pickle_policejob:actions:impoundVehicle", VehToNet(vehicle))
                end,
            }
        }
        lib.registerContext({
            id = menuId,
            title = _L("actions_vehicle_interact"),
            options = options,
        })
        lib.showContext(menuId)
    end, VehToNet(vehicle))
end

function OpenPoliceActionsMenu()
    if IsMenuOpen then return end
    IsMenuOpen = true
    local menuId = "pickle_policejob:actions:menu"
    local options = {
        {
            title = _L("actions_id_card"),
            description = _L("actions_id_card_description"),
            icon = Config.TargetIcons.id_card,
            onSelect = function()
                IsMenuOpen = false
                OpenIDCardMenu()
            end,
        },
        {
            title = _L("actions_vehicle_interact"),
            description = _L("actions_vehicle_interact_description"),
            icon = Config.TargetIcons.vehicle_interact,
            onSelect = function()
                IsMenuOpen = false
                OpenVehicleInteractMenu()
            end,
        },
        {
            title = _L("actions_handcuffs"),
            description = _L("actions_handcuffs_description"),
            icon = Config.TargetIcons.handcuffs,
            onSelect = function()
                IsMenuOpen = false
                EquipHandcuffs()
            end,
        },
        {
            title = _L("actions_drag"),
            description = _L("actions_drag_description"),
            icon = Config.TargetIcons.escort,
            onSelect = function()
                IsMenuOpen = false
                local targetPlayer = GetClosestPlayer()
                if not targetPlayer then return end
                TriggerServerEvent("pickle_policejob:actions:detainment", GetPlayerServerId(targetPlayer), {
                    eventType = "toggleDrag",
                })
            end,
        },
        {
            title = _L("actions_vehicleseat"),
            description = _L("actions_vehicleseat_description"),
            icon = "car",
            onSelect = function()
                IsMenuOpen = false
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
            end,
        },
        {
            title = _L("actions_search"),
            description = _L("actions_search_description"),
            icon = Config.TargetIcons.search,
            onSelect = function()
                IsMenuOpen = false
                OpenNearbyInventory()
            end,
        },
        {
            title = _L("actions_fines"),
            description = _L("actions_fines_description"),
            icon = Config.TargetIcons.fines,
            onSelect = function()
                IsMenuOpen = false
                local targetPlayer = GetClosestPlayer()
                if not targetPlayer then return ShowNotification(_L("no_player_nearby")) end
                ViewFines(GetPlayerServerId(targetPlayer))
            end,
        },
        {
            title = _L("actions_jail"),
            description = _L("actions_jail_description"),
            icon = Config.TargetIcons.jail,
            onSelect = function()
                IsMenuOpen = false
                if Config.Integrations.jail.openJailMenu() then return end
                OpenPoliceJailMenu()
            end,
        },
        {
            title = _L("actions_shields"),
            description = _L("actions_shields_description"),
            icon = Config.TargetIcons.shields,
            onSelect = function()
                IsMenuOpen = false
                UnequipCurrentActions()
                OpenShields()
            end,
        },
        {
            title = _L("actions_snakecam"),
            description = _L("actions_snakecam_description"),
            icon = Config.TargetIcons.snakecam,
            onSelect = function()
                IsMenuOpen = false
                UnequipCurrentActions()
                StartSnakeCam()
            end,
        },
        {
            title = _L("actions_stab_sticks"),
            description = _L("actions_stab_sticks_description"),
            icon = Config.TargetIcons.stab_sticks,
            onSelect = function()
                IsMenuOpen = false
                EquipStabSticks()
            end,
        },

        {
            title = _L("actions_objects"),
            description = _L("actions_objects_description"),
            icon = Config.TargetIcons.objects,
            arrow = true,
            onSelect = function()
                SetTimeout(100, function()
                    OpenObjectPlacementMenu()
                end)
            end,
        }
    }
    if Config.Grappler.enabled then
        table.insert(options, {
            title = _L("actions_grappler"),
            description = _L("actions_grappler_description"),
            icon = Config.TargetIcons.grappler,
            onSelect = function()
                IsMenuOpen = false
                StartGrapplerPlacement()
            end,
        })
    end
    if Config.Evidence.enabled then
        table.insert(options, {
            title = _L("actions_evidence_camera"),
            description = _L("actions_evidence_camera_description"),
            icon = Config.TargetIcons.evidence_camera,
            onSelect = function()
                IsMenuOpen = false
                EquipEvidenceCamera()
            end,
        })
        table.insert(options, {
            title = _L("actions_breathalyzer"),
            description = _L("actions_breathalyzer_description"),
            icon = Config.TargetIcons.breathalyzer,
            onSelect = function()
                IsMenuOpen = false
                EquipBreathalyzer()
            end,
        })
        table.insert(options, {
            title = _L("actions_fingerprint_scanner"),
            description = _L("actions_fingerprint_scanner_description"),
            icon = Config.TargetIcons.fingerprint_scanner,
            onSelect = function()
                IsMenuOpen = false
                EquipFingerprintScanner()
            end,
        })
    end
    lib.registerContext({
        id = menuId,
        title = _L("police_actions_menu"),
        options = options,
        onExit = function()
            IsMenuOpen = false
        end
    })
    lib.showContext(menuId)
end

CreateThread(function()
    Wait(1000)
    if Config.UseTarget then
        AddTargetModel(`npds_p_pb`, 1.0, {
            {
                name = "pickle_policejob:actions:stab_sticks",
                icon = Config.TargetIcons.stab_sticks,
                label = _L("target_stab_sticks"),
                onSelect = function()
                    local closestStick = nil
                    local closestDistance = 100.0
                    for id, data in pairs(StabSticks) do
                        local stick = data.sticks[1]
                        local distance = #(stick.coords - GetEntityCoords(PlayerPedId()))
                        if distance < closestDistance then
                            closestStick = id
                            closestDistance = distance
                        end
                    end
                    if closestStick then
                        TriggerServerEvent("pickle_policejob:actions:deleteStabSticks", closestStick)
                        EquipStabSticks(#StabSticks[closestStick].sticks)
                    end
                end,
            }
        })
    end
    local wait = 1500
    while true do
        local closestId = nil
        local closestDistance = 100.0
        for id, _ in pairs(StabSticks) do
            local isRendered, distance = StabStickRenderProcess(id)
            if isRendered and distance < closestDistance then
                closestId = id
                closestDistance = distance
            end
        end
        if closestId and StabStickGameProcess(closestId) then
            wait = 0
        end
        Wait(wait)
    end
end)

RegisterCommand("policeactions", function()
    if not IsPlayerOnDuty() then return end
    OpenPoliceActionsMenu()
end)

RegisterKeyMapping("policeactions", "Police Actions", "keyboard", "F6")

RegisterNetEvent("pickle_policejob:actions:detainment", function(data)
    local source = GetPlayerServerId(PlayerId())
    if data.eventType == "toggleHandcuffs" then
        if data.cuffed then
            if data.target == source then
                UnequipCurrentActions()
                IsCurrentlyHandcuffed = {}
                local ped = PlayerPedId()
                local targetPed = GetPlayerPed(GetPlayerFromServerId(data.source))
                local targetOffset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 1.0, -1.0)
                SetEntityCoordsNoOffset(ped, targetOffset.x, targetOffset.y, targetOffset.z + 0.5, 0)
                SetEntityHeading(ped, data.heading)
                SetEnableHandcuffs(ped, true)
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) -- unarm player
                PlayAnim(ped, "mp_arrest_paired", "crook_p2_back_left", 8.0, -8.0, 5500, 33, 1.0, false, false, false)
                SetTimeout(5000, function()
                    if not IsCurrentlyHandcuffed then return end
                    IsCurrentlyHandcuffed.prop = CreateProp(`ba_prop_battle_cuffs`, targetOffset.x, targetOffset.y, targetOffset.z + 0.5, true, true, false)
                    local boneIndex = GetPedBoneIndex(ped, 60309)
                    local coords, rot = vector3(-0.035, 0.06, 0.04), vector3(265.25, 153.30, 81.12)
                    AttachEntityToEntity(IsCurrentlyHandcuffed.prop, ped, boneIndex, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, true, false, false, false, 0, true)
                    CreateThread(function()
                        while IsCurrentlyHandcuffed do
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
            if data.source == serverId then
                IsDragging = nil
            elseif data.target == serverId then
                IsDragging = nil
            end
        end
    elseif data.eventType == "toggleVehicleSeat" then
        if data.target ~= GetPlayerServerId(PlayerId()) then
            return
        end
        local vehicle = NetworkGetEntityFromNetworkId(data.netId)
        if not vehicle then return end
        if data.seatId then
            SetEnableHandcuffs(PlayerPedId(), false)
            TaskEnterVehicle(PlayerPedId(), vehicle, -1, 2, 2.0, 1, 0)
            SetTimeout(5000, function()
                SetEnableHandcuffs(PlayerPedId(), true)
            end)
        else
            TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
        end
    end
end)

RegisterNetEvent("pickle_policejob:actions:placeObject", function(id, data)
    local objectCfg = Config.ObjectPlacement.props[data.index]
    if not objectCfg then return end
    ObjectPlacement[id] = data
    ObjectPlacementInteractions[id] = CreateInteraction({
        label = _L("remove_object"),
        icon = Config.TargetIcons.objects,
        coords = data.coords + vector3(0.0, 0.0, 1.0),
        zOffset = objectCfg.targetZOffset or 0.0,
        rotation = data.rotation,
        model = { hash = objectCfg.model, modelType = "prop" },
    }, function()
        TriggerServerEvent("pickle_policejob:actions:deleteObject", id)
    end)
end)

RegisterNetEvent("pickle_policejob:actions:deleteObject", function(id)
    if not ObjectPlacement[id] then return end
    DeleteInteraction(ObjectPlacementInteractions[id])
    ObjectPlacement[id] = nil
    ObjectPlacementInteractions[id] = nil
end)

RegisterNetEvent("pickle_policejob:actions:lockpickVehicle", function(netId)
    if not NetworkDoesNetworkIdExist(netId) then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleDoorsLocked(vehicle, 0)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for id, _ in pairs(StabSticks) do
            UnrenderStabSticks(id)
        end
        UnequipCurrentActions()
        RemoveHandcuffs()
    end
end)