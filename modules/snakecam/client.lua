local Snakecam = {
    Active = false
}

function CreateSnakeCam()
    SetTimecycleModifier("scanline_cam_cheap")
    SetTimecycleModifierStrength(1.5)
    local ped = PlayerPedId()
    local pos, heading = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, -0.75), GetEntityHeading(ped)
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, 0.0, 0.00, heading, 45.00, false, 0)
	SetCamActive(cam, true)
	RenderScriptCams(true, true, 1, true, true)
    return cam
end

function DeleteSnakeCam(cam)
	SetCamActive(cam, false)
	RenderScriptCams(false, true, 1, true, true)
    DestroyCam(cam)
    ClearTimecycleModifier()    
end

function StartSnakeCam()
    if Snakecam.Active then 
        return ShowNotification(_L("snake_active")) 
    end
    local result = lib.callback.await("pickle_policejob:actions:allowedToEquip", false, "snakecam")
    if not result then return end
    Snakecam.Active = true
    CreateThread(function()
        DoScreenFadeOut(1000)
        Wait(1000)
        DoScreenFadeIn(1000)
        local ped = PlayerPedId()
        local cam = CreateSnakeCam()
        local maxSnakeLength = Config.Snakecam.MaxLength
        local ctrl = Config.Snakecam.Controls
        local speed = 0.1
        local startCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.75, -0.75)
        local cancelled = false

        local obj = CreateProp(`bkr_prop_biker_gcase_s`, startCoords.x, startCoords.y, startCoords.z, true, true, false)
        SetEntityHeading(obj, GetEntityHeading(ped))
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        FreezeEntityPosition(ped, true)
        SendNUIMessage({
            displaySnakecam = true,
            value = true
        })
        
        while IsPlayerAlive() do 
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 30, true)
            
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 257, true)
    
            if not IsEntityPlayingAnim(ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", 3) then 
                PlayAnim(ped, "amb@world_human_bum_wash@male@low@idle_a", "idle_a", -8.0, 8.0, -1, 1, 1.0)
            end
    
            local coords = GetCamCoord(cam)
            local rot = GetCamRot(cam, 2)
            local dir = GetDirectionFromRotation(rot) * speed
            local snakeLength = #(coords - startCoords)
            local rx, rz = 0, 0
            local distScale = (snakeLength / maxSnakeLength)
            local str = 1.0 + (3.0 * distScale)
            SetTimecycleModifierStrength(str)
    
            if IsDisabledControlPressed(1, ctrl.up) then
                local newCoords = vector3(coords.x + dir.x, coords.y + dir.y, coords.z + dir.z)
                local newDist = #(newCoords - startCoords)
                if newDist < maxSnakeLength then 
                    SetCamCoord(cam, newCoords.x, newCoords.y, newCoords.z)
                end
            end
            if IsDisabledControlPressed(1, ctrl.down) then
                local newCoords = vector3(coords.x - dir.x, coords.y - dir.y, coords.z - dir.z)
                local newDist = #(newCoords - startCoords)
                if newDist < maxSnakeLength then 
                    SetCamCoord(cam, newCoords.x, newCoords.y, newCoords.z)
                end
            end
            if IsDisabledControlPressed(1, ctrl.look_up) then
                rx = rx + speed * 8
            end
            if IsDisabledControlPressed(1, ctrl.look_down) then
                rx = rx - speed * 8
            end
            if IsDisabledControlPressed(1, ctrl.look_left) then
                rz = rz + speed * 8
            end
            if IsDisabledControlPressed(1, ctrl.look_right) then
                rz = rz - speed * 8
            end
    
            if IsControlPressed(1, ctrl.stop_cam) then 
                cancelled = true
                break
            end
    
            SetCamRot(cam, rot.x + rx, rot.y, rot.z + rz, 2)
            Wait(0)
        end
        DoScreenFadeOut(1000)
        Wait(1000)
        SendNUIMessage({
            displaySnakecam = true,
            value = false
        })
        DeleteSnakeCam(cam)
        DeleteEntity(obj)
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false)
        DoScreenFadeIn(1000)
        Snakecam.Active = false
        TriggerServerEvent("pickle_policejob:tools:snakecam:requestRefund")
    end)
end

RegisterNetEvent("pickle_policejob:tools:snakecam:attemptSnakecam", function()
    StartSnakeCam()
end)