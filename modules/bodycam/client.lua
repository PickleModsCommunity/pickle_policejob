local CurrentBodycam = nil

function DoesPlayerLocallyExist(target)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == target then
            return true
        end
    end
    return false
end

RegisterNetEvent("pickle_policejob:bodycam:startView", function(target, data)
    if CurrentBodycam then return end
    CurrentBodycam = {
        target = target,
    }
    SetFocusArea(data.coords)
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, data.coords.x, data.coords.y, data.coords.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    while not DoesPlayerLocallyExist(target) do
        Wait(100)
    end
    Wait(100)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
    SetFocusEntity(targetPed)
    local boneIndex = GetPedBoneIndex(targetPed, 0x796E)
    HardAttachCamToPedBone(cam, targetPed, 0x796E, 0.0, 90.0, 0.0, 0.0, 0.1, -0.05, true)
    SetTimecycleModifier("scanline_cam")
    SetTimecycleModifierStrength(1.0)
    CreateThread(function()
        SendNUIMessage({
            type = "setBodycamInfo",
            bodycamInfo = {
                rank = data.rank,
                department = data.department,
                name = data.name,
            },
        })
        while CurrentBodycam do
            local channel = MumbleGetVoiceChannelFromServerId(target)
            MumbleSetVoiceChannel(channel)
            Wait(1000)
        end
        SendNUIMessage({
            type = "setBodycamInfo",
            bodycamInfo = nil,
        })
    end)
    while CurrentBodycam do
        if IsControlJustPressed(0, 202) then
            CurrentBodycam = nil
            RenderScriptCams(false, false, 0, true, true)
            SetFocusEntity(PlayerPedId())
            break
        end
        -- DisableControlAction(0, 22, true) 
        -- DisableControlAction(0, 23, true) 
        -- DisableControlAction(0, 24, true)
        -- DisableControlAction(0, 25, true) 
        -- DisableControlAction(0, 30, true) 
        -- DisableControlAction(0, 31, true) 
        -- DisableControlAction(0, 32, true) 
        -- DisableControlAction(0, 34, true) 
        -- DisableControlAction(0, 36, true) 
        -- DisableControlAction(0, 44, true) 
        -- DisableControlAction(0, 45, true) 
        -- DisableControlAction(0, 47, true) 
        -- DisableControlAction(0, 75, true)  
        -- DisableControlAction(0, 140, true) 
        -- DisableControlAction(0, 141, true) 
        -- DisableControlAction(0, 142, true) 
        -- DisableControlAction(0, 143, true) 
        -- DisableControlAction(0, 257, true) 
        -- DisableControlAction(0, 263, true) 
        -- DisableControlAction(0, 264, true) 
        -- DisableControlAction(0, 289, true) 
        Wait(0)
    end
    print("Stopping bodycam")
    SetTimecycleModifier("default")
    SetTimecycleModifierStrength(0.0)
    ClearTimecycleModifier()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        RenderScriptCams(false, false, 0, true, true)
        SetFocusEntity(PlayerPedId())
    end
end)