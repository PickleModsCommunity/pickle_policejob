local Handcuffs = nil

function IsAnythingEquipped()
    return Handcuffs ~= nil
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
            RequestStreamedTextureDict(spriteDict, false)
            DisableControlAction(0, 24, true) -- Left click
            DisableControlAction(0, 25, true) -- Right click
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            local hit, hitCoords, entity = GetDirectionCoords()
            local hasTarget = false
            if hit and GetEntityType(entity) == 1 and #(GetEntityCoords(ped) - hitCoords) < 1.5 then
                hasTarget = true
                if IsDisabledControlJustPressed(0, 24) then
                    
                elseif IsDisabledControlJustPressed(0, 25) then

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

CreateThread(function()
    Wait(1000)
    EquipHandcuffs()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        UnequipHandcuffs()
    end
end)