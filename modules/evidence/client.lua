local shellCasingQueue = {}
local Evidence = {}
local LocalEvidence = {}

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
    localEvidence.interact = CreateInteraction({
        label = _L("evidence_pickup"),
        icon = Config.TargetIcons["evidence"],
        coords = evidence.coords,
        heading = evidence.heading,
    }, function()
        TriggerServerEvent("pickle_policejob:evidence:pickupEvidence", id)
    end)
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
    print("RENDERED EVIDENCE", id, evidence.amount, displayAmount)
end

function UnrenderEvidence(id)
    local localEvidence = LocalEvidence[id]
    if not localEvidence then return end
    localEvidence.rendered = false
    for _, entity in pairs(localEvidence.entities or {}) do
        DeleteEntity(entity)
    end
    localEvidence.entities = {}
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
        for id, data in pairs(LocalEvidence) do
            local evidence = Evidence[id]
            if not evidence then
                RemoveLocalEvidence(id)
            else
                local distance = #(evidence.coords - playerCoords)
                if distance < Config.Evidence.renderDistance then
                    wait = 0
                    if not data.rendered then
                        RenderEvidence(id)
                    end
                    local coords = evidence.coords
                    DrawMarker(32, coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
                    DrawMarker(1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.1, 255, 255, 255, 100, false, true, 2, false, nil, nil, false)
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
    for id, data in pairs(LocalEvidence) do
        RemoveLocalEvidence(id)
    end
end)