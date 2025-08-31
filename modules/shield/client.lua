Shield = {
    Active = false,
    Aiming = false,
    Dict = "doors@1handed",
    Anim =  "l_hand_sweep",
}

function ShieldThread(model)
    local cfg = Config.Shields.Models[model]
    CreateThread(function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local boneIndex = GetPedBoneIndex(ped, 24818)
        
        local obj = CreateProp(model, coords.x, coords.y, coords.z, true, true, false)
        local c,r = table.unpack(cfg.DefaultOffset)
        local c2,r2 = table.unpack(cfg.AimingOffset)

        AttachEntityToEntity(obj, ped, boneIndex, c.x, c.y, c.z, r.x, r.y, r.z, false, false, false, true, true, 2)
        SetWeaponAnimationOverride(ped, `Gang1H`)
        while Shield.Active and IsPlayerAlive() do 
            if (not Shield.Aiming and GetPedConfigFlag(ped, 78, true)) then 
                ClearPedTasks(ped)
                Shield.Dict, Shield.Anim = "weapons@pistol_1h@gang", "aim_med_loop"
                Shield.Aiming = true
                AttachEntityToEntity(obj, ped, boneIndex, c2.x, c2.y, c2.z, r2.x, r2.y, r2.z, false, false, false, true, true, 2)
            elseif (Shield.Aiming and not GetPedConfigFlag(ped, 78, true)) then
                ClearPedTasks(ped)
                Shield.Dict, Shield.Anim = "doors@1handed", "l_hand_sweep"
                Shield.Aiming = false
                AttachEntityToEntity(obj, ped, boneIndex, c.x, c.y, c.z, r.x, r.y, r.z, false, false, false, true, true, 2)
            end
            if not IsEntityPlayingAnim(ped, Shield.Dict, Shield.Anim, 3) then 
                PlayAnim(ped, Shield.Dict, Shield.Anim, -8.0, 8.0, -1, 50, 0.0, 0, 0, 0)
            end
            SetEntityAnimCurrentTime(ped, Shield.Dict, Shield.Anim, 1.0)
            Wait(0)
        end
        Shield.Active = false
        SetWeaponAnimationOverride(ped, `default`)
        ClearPedTasks(ped)
        DeleteEntity(obj)
        RequestShieldRefund()
    end)
end

function GetAllowedShields()
    local data = {}
    for k,v in pairs(Config.Shields.Models) do 
        if IsPlayerOnDuty() then 
            data[k] = v
        end
    end
    return data
end

function RequestShieldRefund()
    TriggerServerEvent("pickle_policejob:actions:requestRefund", "shields")
end

function OpenShields()
    if Shield.Active then 
        Shield.Active = false
    else
        local result = lib.callback.await("pickle_policejob:actions:allowedToEquip", false, "shields")
        if not result then return end
        local _options = {}

        for k,v in pairs(GetAllowedShields()) do
            table.insert(_options, {label = v.Label, description = '', index = k})
        end
        
        if #_options < 1 then 
            ShowNotification(_L("no_shield_available"))
            return RequestShieldRefund() 
        end
        
        lib.registerMenu({
            id = 'pickle_policejob:tools_shields',
            title = 'Shield Selector',
            position = 'top-right',
            options = _options,
            onClose = RequestShieldRefund
        }, function(selected, scrollIndex, args)
            Shield.Active = true
            ShieldThread(_options[selected].index)
        end)
        lib.showMenu('pickle_policejob:tools_shields')
    end
end

RegisterNetEvent("pickle_policejob:tools:shields:openShield", function()
    OpenShields()
end)

RegisterCommand("removeshield", function()
    Shield.Active = false
end)

RegisterKeyMapping('removeshield', 'Put away shield', 'keyboard', 'back')