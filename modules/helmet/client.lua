local Flashlight = {
    Active = false,
    Action = false,
}

local Goggles = {
    Active = false,
    Action = false,
    Vision = 0, -- NVG = 0, TVG = 1
}

local Anims = {
    up = {"anim@mp_helmets@on_foot", "goggles_up"},
    down = {"anim@mp_helmets@on_foot", "goggles_down"},
}

local commandHold = false

function GetCurrentHelmet()
    local ped = PlayerPedId()
    local propIndex = GetPedPropIndex(ped, 0)
    local cfg = Config.Helmets.AllowedProps
    if IsPlayerOnDuty() then 
        for i=1, #cfg do 
            if propIndex == cfg[i].up or propIndex == cfg[i].down then 
                return cfg[i], propIndex
            end
        end 
    end
end

function ToggleGoggles()
    local helmetData = GetCurrentHelmet()
    if Goggles.Action or not helmetData then return end
    Goggles.Action = true
    local ped = PlayerPedId()
    if Goggles.Active then 
        Goggles.Active = false
        PlayAnim(ped, Anims.up[1], Anims.up[2], -8.0, 8.0, -1, 49, 1.0)
        Wait(600)
        SetNightvision(false)
        SetSeethrough(false)
        UpdateHelmet()
        Wait(500)
        ClearPedTasks(ped)
        Goggles.Action = false
    else
        Goggles.Active = true
        PlayAnim(ped, Anims.down[1], Anims.down[2], -8.0, 8.0, -1, 49, 1.0)
        Wait(600)
        UpdateHelmet()
        UpdateVision()
        Wait(500)
        ClearPedTasks(ped)
        CreateThread(function() 
            while Goggles.Active and GetCurrentHelmet() do 
                Wait(0)
            end
            if not GetCurrentHelmet() then 
                SetNightvision(false)
                SetSeethrough(false)
                Goggles.Active = false
            end
        end)   
        Goggles.Action = false
    end
end

function UpdateHelmet()
    local ped = PlayerPedId()
    local drawableId, textureId = nil, GetPedPropTextureIndex(ped, 0)
    local helmetData = GetCurrentHelmet()
    if helmetData then 
        if Goggles.Active then 
            drawableId = helmetData.down
        else
            drawableId = helmetData.up
        end
        SetPedPropIndex(ped, 0, drawableId, textureId, true)
    end
end

function UpdateVision()
    local index = Goggles.Vision
    if index == 0 then -- NVG
        SetNightvision(true)
        SetSeethrough(false)
    elseif index == 1 then -- TVG
        SetNightvision(false)
        SetSeethrough(true)
    end
end

function ToggleGoggleVision()
    local helmetData = GetCurrentHelmet()
    if not Goggles.Active or not helmetData then return end
    local index = Goggles.Vision + 1
    if index > 1 then 
        index = 0
    end
    Goggles.Vision = index
    local ped = PlayerPedId()
    PlayAnim(ped, Anims.up[1], Anims.up[2], -8.0, 8.0, -1, 49, 1.0)
    Wait(400)
    ClearPedTasks(ped)
    UpdateVision()
end

function ToggleFlashlight()
    local helmetData = GetCurrentHelmet()
    if Flashlight.Action or not helmetData then return end
    Flashlight.Action = true
    local ped = PlayerPedId()
    if Flashlight.Active then 
        PlayAnim(ped, Anims.up[1], Anims.up[2], -8.0, 8.0, -1, 49, 1.0)
        Wait(400)
        ClearPedTasks(ped)
        TriggerServerEvent("pickle_policejob:tools:goggles:setFlashlight", false)
        Flashlight.Active = false
        Flashlight.Action = false
    else
        PlayAnim(ped, Anims.up[1], Anims.up[2], -8.0, 8.0, -1, 49, 1.0)
        Wait(400)
        ClearPedTasks(ped)
        TriggerServerEvent("pickle_policejob:tools:goggles:setFlashlight", true)
        Flashlight.Active = true
        Flashlight.Action = false
        CreateThread(function() 
            while Flashlight.Active and GetCurrentHelmet() do 
                Wait(0)
                DrawHelmetFlashlight()
            end
            Flashlight.Active = false
            TriggerServerEvent("pickle_policejob:tools:goggles:setFlashlight", false)
        end)        
    end
end

function DrawHelmetFlashlight(ped, aiming)
    local boneID = 0x322C
    if ped then
        local offset = (aiming and 20.0 or 0.0)
        local boneIndex = GetPedBoneIndex(ped, boneID)
        local coords = GetWorldPositionOfEntityBone(ped, boneIndex)
        local rot = GetEntityBoneRotation(ped, boneIndex)
        local rot = vector3(rot.x + offset, rot.y, GetEntityHeading(ped))
        local dir = GetDirectionFromRotation(rot)
        DrawSpotLight(coords.x, coords.y, coords.z, dir.x, dir.y, dir.z, 255, 255, 255, 50.0, 1.0, 0.0, 4.0, 1.0)
    else
        local ped = PlayerPedId()
        local boneIndex = GetPedBoneIndex(ped, boneID)
        local coords = GetWorldPositionOfEntityBone(ped, boneIndex)
        local rot = GetGameplayCamRot(2)
        local heading = GetClampedHeading(GetEntityHeading(ped), rot.z)
        if heading then 
            local rot = vector3(rot.x, rot.y, heading)
            local dir = GetDirectionFromRotation(rot)
            DrawSpotLight(coords.x, coords.y, coords.z, dir.x, dir.y, dir.z, 255, 255, 255, 50.0, 1.0, 0.0, 4.0, 1.0)
        end
    end
end

if Config.Helmets.EnableFlashlights then
    CreateThread(function() 
        while true do 
            local wait = 1000
            local localPlayer = PlayerId()
            local localPed = PlayerPedId()
            local localServerID = GetPlayerServerId(localPlayer)
            local localCoords = GetEntityCoords(localPed)
            local players = GetActivePlayers()
            for i=1, #players do 
                local player = players[i]
                local id = GetPlayerServerId(player)
                if player ~= -1 and localPlayer ~= player and localServerID ~= id and GlobalState.ActiveFlashlights[id] then 
                    local ped = GetPlayerPed(player)
                    if ped ~= localPed then 
                        local pedCoords = GetEntityCoords(ped)
                        local dist = #(localCoords - pedCoords)
                        if dist < 100 and dist > 1.0 then 
                            wait = 0
                            DrawHelmetFlashlight(ped, GetPedConfigFlag(ped, 78, true))
                        end
                    end
                end
            end
            Wait(wait)
        end
    end)

    RegisterCommand("togglegoggles", function()
        ToggleGoggles()
    end, false)

    RegisterCommand("+togglegogglevision", function()
        commandHold = true
        for i=1, 20 do
            if not commandHold then 
                ToggleGoggleVision()
                break
            end 
            Wait(0)
        end
        if commandHold then 
            ToggleFlashlight()
        end 
    end, false)

    RegisterCommand("-togglegogglevision", function()
        commandHold = false
    end, false)

    RegisterKeyMapping('togglegoggles', 'Toggle Goggles', 'keyboard', 'f11')

    RegisterKeyMapping('+togglegogglevision', 'Toggle Goggle Vision', 'keyboard', 'g')
end