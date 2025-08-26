local shellCasingQueue = {}
local Evidence = {}
local LocalEvidence = {}
local IN_EVIDENCE_CAMERA = false
local HIDE_EVIDENCE_MARKERS = false
local CAMERA_EVIDENCE = {}
local ReconstructScene


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

function EquipEvidenceCamera(trackData)
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
        local cameraState = "idle"
        local scanTime = 0
        local enableInteract = true
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
            
            if enableInteract then
                if IsControlJustPressed(0, 202) then
                    break
                elseif IsDisabledControlJustPressed(0, 33) then
                    TriggerServerEvent("pickle_policejob:evidence:saveEvidence", "camera", CAMERA_EVIDENCE)
                    CAMERA_EVIDENCE = {}
                    break
                elseif IsDisabledControlJustPressed(1, 51) then
                    enableInteract = false
                    CreateThread(function()
                        local p = promise.new()
                        exports['screenshot-basic']:requestScreenshotUpload(Config.Photos.url, Config.Photos.uploadProtocol, function(data)
                            local resp = json.decode(data)
                            local image = Config.Photos.ResponseHandler(resp)
                            table.insert(CAMERA_EVIDENCE, {
                                type = "photo",
                                label = _L("photo"),
                                image = image,
                                coords = GetEntityCoords(playerPed),
                                heading = GetEntityHeading(playerPed),
                            })
                            SendNUIMessage({
                                type = "setCameraEvidence",
                                evidence = CAMERA_EVIDENCE,
                            })
                            p:resolve(true)
                        end)
                        Citizen.Await(p)
                        enableInteract = true
                    end)
                end
            end
            if cameraState == "idle" then
                if IsDisabledControlJustPressed(0, 22) and enableInteract then
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
                        local isTargetVehicle = (DoesEntityExist(entity) and GetEntityType(entity) == 2)
                        print(isTargetVehicle, entity)
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
                        cameraState = ((targetVisible or isTargetVehicle) and "match" or "no_match")
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
                        if targetVisible or isTargetVehicle then
                            local p = promise.new()
                            HIDE_EVIDENCE_MARKERS = true
                            CreateThread(function()
                                Wait(100)
                                exports['screenshot-basic']:requestScreenshotUpload(Config.Photos.url, Config.Photos.uploadProtocol, function(data)
                                    local resp = json.decode(data)
                                    local image = Config.Photos.ResponseHandler(resp)
                                    if targetVisible then
                                        local data = Evidence[targetVisible]
                                        data.image = image
                                        table.insert(CAMERA_EVIDENCE, data)
                                        print(json.encode(data, {indent = true}))
                                        SendNUIMessage({
                                            type = "setCameraEvidence",
                                            evidence = CAMERA_EVIDENCE,
                                        })
                                        p:resolve(true)
                                    else
                                        lib.callback("pickle_policejob:evidence:getVehicleInfo", false, function(data)
                                            data.type = "vehicle"
                                            data.model = GetEntityModel(entity)
                                            data.label = _L("vehicle")
                                            data.image = image
                                            table.insert(CAMERA_EVIDENCE, data)
                                            SendNUIMessage({
                                                type = "setCameraEvidence",
                                                evidence = CAMERA_EVIDENCE,
                                            })
                                            p:resolve(true)
                                        end, VehToNet(entity))
                                    end
                                end)
                                local success = Citizen.Await(p)
                                HIDE_EVIDENCE_MARKERS = false
                                if success and targetVisible then
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
    EquipEvidenceCamera()
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

function GenerateEvidenceEntities(evidence)
    local entities = {}
    local decals = {}
    evidence.coords = vector3(evidence.coords.x, evidence.coords.y, evidence.coords.z)
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
            table.insert(entities, entity)
        end
    elseif evidence.type == "blood" then
        table.insert(decals, AddDecal(1010, evidence.coords.x, evidence.coords.y, evidence.coords.z, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0, 0.8, 0.5, 0.5, 0.0, 0.0, 1.0, -1, false, false, false))
    elseif evidence.type == "fire" then
        table.insert(decals, AddDecal(4421, evidence.coords.x, evidence.coords.y, evidence.coords.z, 0.0, 0.0, -1.0, 0.0, 1.0, 0.0, 0.8, 0.5, 0.5, 0.0, 0.0, 1.0, -1, false, false, false))
    elseif evidence.type == "vehicle" then
        local vehicle = CreateVeh(evidence.model, evidence.coords, evidence.heading, false, false)
        FreezeEntityPosition(vehicle, true)
        SetEntityCollision(vehicle, false, false)
        SetEntityInvincible(vehicle, true)
        SetEntityAlpha(vehicle, 127, false)
        table.insert(entities, vehicle)
    end
    return entities, decals
end

function RenderEvidence(id)
    local localEvidence = LocalEvidence[id]
    local evidence = Evidence[id]
    if not localEvidence or not evidence then return end
    UnrenderEvidence(id)
    localEvidence.rendered = true
    localEvidence.interact = CreateInteraction({
        label = _L("evidence_pickup"),
        icon = Config.TargetIcons["evidence"],
        coords = evidence.coords,
        heading = evidence.heading,
    }, function()
        TriggerServerEvent("pickle_policejob:evidence:pickupEvidence", id)
    end)
    local entities, decals = GenerateEvidenceEntities(evidence)
    localEvidence.entities = entities
    localEvidence.decals = decals
end

function UnrenderEvidence(id)
    local localEvidence = LocalEvidence[id]
    if not localEvidence then return end
    localEvidence.rendered = false
    for _, entity in pairs(localEvidence.entities or {}) do
        DeleteEntity(entity)
    end
    localEvidence.entities = {}
    if localEvidence.decals then
        for _, decal in pairs(localEvidence.decals) do
            RemoveDecal(decal)
        end
        localEvidence.decals = {}
    end
    if localEvidence.interact then
        DeleteInteraction(localEvidence.interact)
        localEvidence.interact = nil
    end
end

function DrawTextAtCoords(coords, text)
    local coords = vector3(coords.x, coords.y, coords.z + 0.5)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(coords - playerCoords)
    local baseScale = 0.5
    local scale = baseScale * math.max(0.1, 1.0 - (distance / 20.0))
    if onScreen then
        BeginTextCommandDisplayText('STRING')
        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(1)
        SetTextOutline()
        AddTextComponentString(text)
        SetTextEntry("STRING")
        DrawText(screenX, screenY)
    end
end

function UnrenderReconstructedEvidence(id)
    local renderedEvidence = ReconstructScene.renderedEvidence[id]
    if not renderedEvidence then return end
    for _, entity in pairs(renderedEvidence.entities) do
        DeleteEntity(entity)
    end
    for _, decal in pairs(renderedEvidence.decals) do
        RemoveDecal(decal)
    end
    ReconstructScene.renderedEvidence[id] = nil
end

function RenderReconstructedEvidence(id)
    local evidence = ReconstructScene.evidence[id]
    if not evidence then return end
    UnrenderReconstructedEvidence(id)
    local entities, decals = GenerateEvidenceEntities(evidence)
    ReconstructScene.renderedEvidence[id] = {
        entities = entities,
        decals = decals,
    }
end

function StopReconstructedScene()
    if ReconstructScene then
        for i=1, #ReconstructScene.evidence do
            UnrenderReconstructedEvidence(i)
        end
        ReconstructScene = nil
    end
end

RegisterNUICallback("getEvidenceItems", function(data, cb)
    lib.callback("pickle_policejob:evidence:getEvidenceItems", false, function(data)
        cb(data)
    end)
end)

RegisterNUICallback("createFile", function(data, cb)
    lib.callback("pickle_policejob:evidence:createFile", false, function(data)
        SendNUIMessage({
            type = "openFile",
            file = data,
        })
        cb(true)
    end, data)
end)

RegisterNUICallback("updateFileDocument", function(data, cb)
    TriggerServerEvent("pickle_policejob:evidence:updateFileDocument", data.id, data.content)
    cb(true)
end)

RegisterNUICallback("deleteEvidenceItem", function(data, cb)
    lib.callback("pickle_policejob:evidence:deleteEvidenceItem", false, function(data)
        cb(data)
    end, data.name, data.slot)
end)

RegisterNUICallback("importEvidence", function(data, cb)
    TriggerServerEvent("pickle_policejob:evidence:importEvidence", data.id, data.evidence)
    cb(true)
end)

RegisterNUICallback("printFile", function(data, cb)
    TriggerServerEvent("pickle_policejob:evidence:printFile", data.id)
    cb(true)
end)

RegisterNUICallback("getFiles", function(data, cb)
    lib.callback("pickle_policejob:evidence:getFiles", false, function(data)
        local results = {}  
        for _, row in ipairs(data) do
            table.insert(results, {
                id = row.id,
                name = row.name,
                authorIdentifier = row.authorIdentifier,
                datetime = row.datetime,
                evidence = json.decode(row.evidence),
                document = json.decode(row.document),
            })
        end
        cb(results)
    end, data.search)
end)

RegisterNUICallback("closeFileViewer", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "setFileViewer",
    })
    cb(true)
end)

RegisterNUICallback("reconstructScene", function(data, cb)
    cb(true)
    if ReconstructScene then
        StopReconstructedScene()
        return
    end
    ReconstructScene = {
        id = data.file.id,
        evidence = data.file.evidence,
        renderedEvidence = {},
    }
    CreateThread(function()
        while ReconstructScene do
            local bulletEvidenceCount = 0
            local playerCoords = GetEntityCoords(PlayerPedId())
            for i=1, #ReconstructScene.evidence do
                local evidence = ReconstructScene.evidence[i]
                local coords = vector3(evidence.coords.x, evidence.coords.y, evidence.coords.z)
                if ReconstructScene.renderedEvidence[i] then
                    if not evidence.type or evidence.type == "photo" then
                        DrawMarker(6, coords.x, coords.y, coords.z + 0.45, 0.0, 0.0, 0.0, 0.0, 0.0, evidence.heading, 0.6, 0.6, 0.6, 255, 255, 255, 100, false, false, 2, false, nil, nil, false)
                        DrawMarker(6, coords.x, coords.y, coords.z + 0.45, 0.0, 0.0, 0.0, 0.0, 0.0, evidence.heading, 0.3, 0.3, 0.3, 255, 255, 255, 100, false, false, 2, false, nil, nil, false)
                    elseif evidence.type ~= "vehicle" then
                        DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.1, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                    end
                    DrawTextAtCoords(coords, "#"..i)
                    if evidence.type == "shell_casing" then
                        bulletEvidenceCount = bulletEvidenceCount + 1
                        DrawLine(coords.x, coords.y, coords.z + 1.5, evidence.direction.x, evidence.direction.y, evidence.direction.z, 255, 0, 0, 255 / (bulletEvidenceCount / 2))
                    end
                    if #(coords - playerCoords) > Config.Evidence.reconstructRenderDistance then
                        UnrenderReconstructedEvidence(i)
                    end
                else
                    if #(coords - playerCoords) < Config.Evidence.renderDistance then
                        RenderReconstructedEvidence(i)
                    end
                end
            end
            Wait(0)
        end
    end)
end)

RegisterNUICallback("deleteEvidence", function(data, cb)
    TriggerServerEvent("pickle_policejob:evidence:deleteEvidence", data.id, data.index)
    cb(true)
end)

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

RegisterNetEvent("pickle_policejob:evidence:viewFile", function(file)
    SendNUIMessage({
        type = "setFileViewer",
        file = file,
        reconstructSceneId = ReconstructScene and ReconstructScene.id or nil,
    })
    SetNuiFocus(true, true)
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
    StopReconstructedScene()
    for id, data in pairs(LocalEvidence) do
        RemoveLocalEvidence(id)
    end
end)

AddEventHandler('gameEventTriggered', function (name, args)
    if name == "CEventNetworkEntityDamage" then 
        local victim = args[1]
        local attacker = args[2]
        -- if victim ~= PlayerPedId() or not DoesEntityExist(attacker) then return end
        TriggerServerEvent("pickle_policejob:evidence:addBlood")
    elseif name == "CEventNetworkPlayerEnteredVehicle" then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if not DoesEntityExist(vehicle) or PlayerPedId() ~= GetPlayerPed(args[1]) then return end
        for i=-1, 6 do
            local pedSeat = GetPedInVehicleSeat(vehicle, i)
            if pedSeat == PlayerPedId() then
                TriggerServerEvent("pickle_policejob:evidence:addVehiclePrint", VehToNet(vehicle), i)
                break
            end
        end
    end
end)
  
