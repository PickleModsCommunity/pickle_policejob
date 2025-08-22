local shellCasingQueue = {}
local Evidence = {}
local LocalEvidence = {}
local IN_EVIDENCE_CAMERA = false
local HIDE_EVIDENCE_MARKERS = false
local CAMERA_EVIDENCE = {}

-- EVIDENCE CAMERA

local CAMERA_VALUES = {}
CAMERA_VALUES.fov = { 10.0, 90.0 }
CAMERA_VALUES.calculatedFov = CAMERA_VALUES.fov[2]
CAMERA_VALUES.speed = { zoom = 10.0, x = 8.0, y = 8.0 }

local function HideHUD()
    local hiddenComponents = {1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 15, 18, 19}
    for i=1, #hiddenComponents do
        HideHudComponentThisFrame(hiddenComponents[i])
    end
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
end

function CameraControls(cam, zoom)
    local playerPed = PlayerPedId()
    local rightAxis = {x = GetDisabledControlNormal(0, 220), y = GetDisabledControlNormal(0, 221)}
    local rotation = GetCamRot(cam, 2)
    if IsControlJustPressed(0, IsPedSittingInAnyVehicle(playerPed) and 17 or 241) then
        CAMERA_VALUES.calculatedFov = math.max(CAMERA_VALUES.calculatedFov - CAMERA_VALUES.speed.zoom, CAMERA_VALUES.fov[1])
    end
    if IsControlJustPressed(0, IsPedSittingInAnyVehicle(playerPed) and 16 or 242) then
        CAMERA_VALUES.calculatedFov = math.min(CAMERA_VALUES.calculatedFov + CAMERA_VALUES.speed.zoom, CAMERA_VALUES.fov[2])
    end
    local current_fov = GetCamFov(cam)
    if math.abs(CAMERA_VALUES.calculatedFov-current_fov) < 0.1 then
        CAMERA_VALUES.calculatedFov = current_fov
    end
    SetCamFov(cam, current_fov + (CAMERA_VALUES.calculatedFov - current_fov)*0.05)
    SetEntityHeading(playerPed, rotation.z)
    if rightAxis.x ~= 0.0 or rightAxis.y ~= 0.0 then
        local new_z = rotation.z + rightAxis.x*-1.0*(CAMERA_VALUES.speed.y)*(zoom+0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxis.y*-1.0*(CAMERA_VALUES.speed.x)*(zoom+0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end
end

function CameraLoop(trackData)
    if IN_EVIDENCE_CAMERA then return end
    IN_EVIDENCE_CAMERA = true
    local playerPed = PlayerPedId()
    CreateThread(function()
        local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
        AttachCamToEntity(cam, playerPed, 0.0, 1.0, 0.75, true)
        SetCamFov(cam, CAMERA_VALUES.calculatedFov)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(playerPed), 2)
        RenderScriptCams(true, false, 0, true, false)
        local obj = CreateProp(`prop_pap_camera_01`, GetEntityCoords(playerPed), true, true)
        CAMERA_VALUES.obj = obj
        local boneIndex = GetPedBoneIndex(playerPed, 28422)
        AttachEntityToEntity(obj, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        local targetPed = nil
        local cameraState = "idle"
        local scanTime = 0
        SendNUIMessage({
            type = "setCameraState",
            cameraState = cameraState
        })
        SendNUIMessage({
            type = "setCameraEvidence",
            evidence = CAMERA_EVIDENCE,
        })
        CreateThread(function()
            while IN_EVIDENCE_CAMERA do
                SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
                if not IsEntityPlayingAnim(playerPed, "amb@world_human_paparazzi@male@base", "base", 3) then
                    ClearPedTasksImmediately(playerPed)
                    PlayAnim(playerPed, "amb@world_human_paparazzi@male@base", "base", -8.0, 8.0, -1, 49, 0, false, false, false)
                end
                Wait(1000)
            end
        end)
        while IN_EVIDENCE_CAMERA and not IsPedInAnyVehicle(playerPed) and not IsEntityDead(playerPed) do
            HideHUD()
            CameraControls(cam, (1.0 / (CAMERA_VALUES.fov[2] - CAMERA_VALUES.fov[1])) * (CAMERA_VALUES.calculatedFov - CAMERA_VALUES.fov[1]))
            DisableControlAction(0, 30, true)  -- Disable move left/right
            DisableControlAction(0, 31, true)  -- Disable move up/down
            DisableControlAction(0, 21, true)  -- Disable sprint
            DisableControlAction(0, 22, true)  -- Disable jump
            DisableControlAction(0, 24, true)  -- Disable attack
            DisableControlAction(0, 25, true)  -- Disable aim
            DisableControlAction(0, 37, true)  -- Disable weapon select
            DisableControlAction(0, 44, true)  -- Disable cover
            DisableControlAction(0, 140, true) -- Disable melee attack light
            DisableControlAction(0, 141, true) -- Disable melee attack heavy
            DisableControlAction(0, 142, true) -- Disable melee attack alternate
            DisableControlAction(0, 143, true) -- Disable melee block
            if IsControlJustPressed(0, 202) then
                CreateThread(function()
                    if #CAMERA_EVIDENCE <= 0 then return end
                    local alert = lib.alertDialog({
                        header = _L("camera_save_evidence"),
                        content = _L("camera_save_evidence_desc"),
                        centered = true,
                        cancel = true
                    })
                    if alert == "confirm" then
                        TriggerServerEvent("pickle_policejob:evidence:saveEvidence", CAMERA_EVIDENCE)
                        CAMERA_EVIDENCE = {}
                    end
                end)
                break
            end
            if cameraState == "idle" then
                if IsDisabledControlJustPressed(0, 22) then
                    cameraState = "scanning"
                    SendNUIMessage({
                        type = "setCameraState",
                        cameraState = cameraState
                    })
                end
            elseif cameraState == "scanning" then
                if IsDisabledControlJustReleased(0, 22) then
                    cameraState = "idle"
                    scanTime = 0
                    SendNUIMessage({
                        type = "setCameraState",
                        cameraState = cameraState
                    })
                else
                    scanTime = scanTime + 1
                    if scanTime >= 25 then
                        local hit, hitCoords, entity = GetDirectionCoords(GetCamCoord(cam), GetCamRot(cam, 2))
                        local targetVisible = nil
                        if hit then
                            local closestDistance = 2.0
                            for id, evidence in pairs(Evidence) do
                                local distance = #(hitCoords - evidence.coords)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    targetVisible = id
                                end
                            end
                        end
                        cameraState = (targetVisible and "match" or "no_match")
                        scanTime = 0
                        SendNUIMessage({
                            type = "setCameraState",
                            cameraState = cameraState
                        })
                        SetTimeout(1000, function()
                            if cameraState ~= nil then
                                cameraState = "idle"
                                SendNUIMessage({
                                    type = "setCameraState",
                                    cameraState = cameraState
                                })
                            end
                        end)
                        if targetVisible then
                            local p = promise.new()
                            HIDE_EVIDENCE_MARKERS = true
                            CreateThread(function()
                                Wait(100)
                                exports['screenshot-basic']:requestScreenshotUpload(Config.Photos.url, Config.Photos.uploadProtocol, function(data)
                                    local resp = json.decode(data)
                                    table.insert(CAMERA_EVIDENCE, {
                                        label = Evidence[targetVisible].label,
                                        image = Config.Photos.ResponseHandler(resp)
                                    })
                                    SendNUIMessage({
                                        type = "setCameraEvidence",
                                        evidence = CAMERA_EVIDENCE,
                                    })
                                    p:resolve(true)
                                end)
                                local success = Citizen.Await(p)
                                HIDE_EVIDENCE_MARKERS = false
                                if success then
                                    TriggerServerEvent("pickle_policejob:evidence:pickupEvidence", targetVisible)
                                end
                            end)
                        end
                    end
                end
            end
            Wait(0)
        end
        StopCameraLoop()
    end)
end

function StopCameraLoop()
    if CAMERA_VALUES.obj then
        DeleteEntity(CAMERA_VALUES.obj)
        CAMERA_VALUES.obj = nil
    end
    ClearPedTasksImmediately(PlayerPedId())
    IN_EVIDENCE_CAMERA = false
    cameraState = nil
    SendNUIMessage({
        type = "setCameraState",
        cameraState = cameraState,
    })
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    CAMERA_VALUES.calculatedFov = CAMERA_VALUES.fov[2]
end

RegisterCommand("ecam", function()
    CameraLoop()
end, false)

-- Evidence Core

function GetWeaponGroupFromHash(weaponGroup)
    for k, v in pairs(Config.Evidence.weaponGroups) do
        if GetHashKey(k) == weaponGroup then
            return k, v
        end
    end
end

function AddShellCasingToQueue(data)
    table.insert(shellCasingQueue, data)
    if #shellCasingQueue > 1 then return end
    CreateThread(function()
        print("STARTING QUEUE")
        while #shellCasingQueue > 0 do
            Wait(math.floor(1000 * Config.Evidence.queueInterval))
            local firstCasing = shellCasingQueue[1]
            local removedCasings = {}
            local amount = 1
            for i=#shellCasingQueue, 2, -1 do
                local casing = shellCasingQueue[i]
                local distance = #(firstCasing.direction - casing.direction)
                if distance < Config.Evidence.evidenceGroupDistance then
                    table.insert(removedCasings, i)
                    amount = amount + 1
                end
            end
            local newCasings = {}
            for i=1, #shellCasingQueue do
                local add = true
                for j=1, #removedCasings do
                    if i == removedCasings[j] then
                        add = false
                    end
                end
                if add then
                    table.insert(newCasings, shellCasingQueue[i])
                end
            end
            shellCasingQueue = newCasings
            firstCasing.amount = amount
            TriggerServerEvent("pickle_policejob:evidence:addShellCasing", firstCasing)
            table.remove(shellCasingQueue, 1)
        end
    end)
end

function AddLocalEvidence(id, data)
    if not Evidence[id] then return end
    if LocalEvidence[id] then RemoveLocalEvidence(id) end
    LocalEvidence[id] = { rendered = false }
    RenderEvidence(id)
end

function RemoveLocalEvidence(id)
    UnrenderEvidence(id)
    LocalEvidence[id] = nil
end

function RenderEvidence(id)
    local localEvidence = LocalEvidence[id]
    local evidence = Evidence[id]
    if not localEvidence or not evidence then return end
    UnrenderEvidence(id)
    localEvidence.rendered = true
    localEvidence.entities = {}
    print(evidence.coords)
    localEvidence.interact = CreateInteraction({
        label = _L("evidence_pickup"),
        icon = Config.TargetIcons["evidence"],
        coords = evidence.coords,
        heading = evidence.heading,
    }, function()
        TriggerServerEvent("pickle_policejob:evidence:pickupEvidence", id)
    end)
    if evidence.type == "shell_casing" then
        local displayAmount = evidence.amount
        if displayAmount > Config.Evidence.maxDisplayAmount then
            displayAmount = Config.Evidence.maxDisplayAmount
        end
        local weaponGroup = Config.Evidence.weaponGroups[evidence.weaponGroup or "GROUP_PISTOL"] or Config.Evidence.weaponGroups["GROUP_PISTOL"]
        local model = weaponGroup.shellModel
        local rotation = weaponGroup.shellRotation
        local rootObject
        for i=1, displayAmount do
            local entity = CreateProp(model, evidence.coords, false, false, false)
            local baseHeading = 90.0
            if not rootObject then
                rootObject = entity
            else
                local coords = GetOffsetFromEntityInWorldCoords(rootObject, (i-1) * 0.035, (i-1) * 0.035, 0.0)
                SetEntityCoords(entity, coords)
                baseHeading = baseHeading + ((math.random(1, 2) == 1 and 1 or -1) * math.random(5, 20))
            end
            
            SetEntityHeading(entity, evidence.heading + baseHeading + rotation.z)
            FreezeEntityPosition(entity, true)
            PlaceObjectOnGroundProperly(entity)
            table.insert(localEvidence.entities, entity)
        end
    elseif evidence.type == "blood" then
        local width = 0.8
        local height = 0.5
        localEvidence.decal = AddDecal(1010, evidence.coords.x, evidence.coords.y, evidence.coords.z, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0, width, height, 0.5, 0.0, 0.0, 1.0, -1, false, false, false)
    end
end

function UnrenderEvidence(id)
    local localEvidence = LocalEvidence[id]
    if not localEvidence then return end
    localEvidence.rendered = false
    for _, entity in pairs(localEvidence.entities or {}) do
        DeleteEntity(entity)
    end
    localEvidence.entities = {}
    if localEvidence.decal then
        RemoveDecal(localEvidence.decal)
        localEvidence.decal = nil
    end
    if localEvidence.interact then
        DeleteInteraction(localEvidence.interact)
        localEvidence.interact = nil
    end
end

RegisterNetEvent("pickle_policejob:evidence:addEvidence", function(id, data)
    Evidence[id] = data
    AddLocalEvidence(id, data)
end)

RegisterNetEvent("pickle_policejob:evidence:updateEvidence", function(id, data)
    Evidence[id] = data
    if #(GetEntityCoords(PlayerPedId()) - data.coords) < Config.Evidence.renderDistance then
        RenderEvidence(id)
    end
end)

RegisterNetEvent("pickle_policejob:evidence:removeEvidence", function(id)
    Evidence[id] = nil
    RemoveLocalEvidence(id)
end)

CreateThread(function()
    while true do
        local wait = 1500
        local playerPed = PlayerPedId()
        if IsPedArmed(playerPed, 4) then
            wait = 0
            if IsPedShooting(playerPed) then
                local _, weaponHash = GetCurrentPedWeapon(playerPed)
                local weaponGroup = GetWeaponGroupFromHash(GetWeapontypeGroup(weaponHash))
                local origin = GetEntityCoords(playerPed) - vector3(0.0, 0.0, 1.0)
                local hit, hitCoords, entity = GetDirectionCoords()
                local direction = hit and hitCoords or origin + vector3(0.0, 0.0, 0.01)
                local heading = GetHeadingFromVector_2d(direction.x - origin.x, direction.y - origin.y)
                AddShellCasingToQueue({
                    weaponHash = weaponHash,
                    weaponGroup = weaponGroup,
                    origin = origin,
                    direction = direction,
                    heading = heading,
                })
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local wait = 1500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local bulletEvidenceCount = 0
        for id, data in pairs(LocalEvidence) do
            local evidence = Evidence[id]
            if not evidence then
                RemoveLocalEvidence(id)
            else
                local distance = #(evidence.coords - playerCoords)
                if distance < Config.Evidence.renderDistance then
                    if not data.rendered then
                        if not evidence.calculatedGroundZ then
                            local _, groundZ = GetGroundZFor_3dCoord(evidence.coords.x, evidence.coords.y, evidence.coords.z, false)
                            evidence.coords = vector3(evidence.coords.x, evidence.coords.y, groundZ)
                            evidence.calculatedGroundZ = true
                        end
                        RenderEvidence(id)
                    end
                    if IN_EVIDENCE_CAMERA and not HIDE_EVIDENCE_MARKERS then
                        wait = 0
                        local coords = evidence.coords
                        DrawMarker(32, coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                        DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.1, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                        if evidence.type == "shell_casing" then
                            bulletEvidenceCount = bulletEvidenceCount + 1
                            DrawLine(coords.x, coords.y, coords.z + 1.5, evidence.direction.x, evidence.direction.y, evidence.direction.z, 255, 0, 0, 255 / (bulletEvidenceCount / 2))
                        end
                    end
                else
                    if data.rendered then
                        UnrenderEvidence(id)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    StopCameraLoop()
    for id, data in pairs(LocalEvidence) do
        RemoveLocalEvidence(id)
    end
end)

AddEventHandler('gameEventTriggered', function (name, args)
    if name ~= "CEventNetworkEntityDamage" then return end
    local victim = args[1]
    local attacker = args[2]
    if victim ~= PlayerPedId() or not DoesEntityExist(attacker) then return end
    TriggerServerEvent("pickle_policejob:evidence:addBlood")
end)
  