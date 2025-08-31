Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"
Config.WeaponsAreItems = true -- This enables the use of weapons as items. If set to false, weapons will be treated as items and not as weapons.
Config.TeleportEscortIntoSeat = false -- This enables the teleportation of the escort to the seat of the vehicle. Default animates entry / exit.
Config.DefaultJob = { name = "unemployed", level = 0 } -- The job to set players to when they clock off-duty.
Config.Photos = {
    url = "https://fmapi.net/api/v2/image?apiKey=vX7G4UCDJLUSm19U1DGSdvUUpEiOSERv", -- By default, uses discord to host images.
    uploadProtocol = 'file',
    ResponseHandler = function(resp) -- Return URL from response.
       return resp.data.url
    end,
}

Config.Finance = {
    disableWithdraw = false, -- When true, the department will not be able to withdraw money from the department's funds.
    deductCostsFromDepartment = true, -- When true, the costs will be deducted from the department's funds - otherwise it will be deducted from the player's funds.
    deductSalaryFromDepartment = true, -- When true, the salary will be deducted from the department's funds - if it is too much it will not pay. False pays out without deducting.
    maxRankSalary = 10000, -- The maximum salary a rank can have.
    salarySchedule = "*/15 * * * *", -- The CRON schedule at which the salary will be paid. Default is every 15 minutes.
    funding = 100000, -- The amount of money to fund the department with per schedule.
    fundingSchedule = "*/15 * * * *", -- The CRON schedule at which the funding will be paid. Default is every 15 minutes.
    maxTransactions = 100, -- The maximum number of transactions to store per department.
}

Config.Currency = { currency = "USD", countryCode = "en-US" } -- Look up JS currency and countryCode variables for more options. 

-- The above should always be configured before using the resource.

Config.DepartmentBlip = {
    sprite = 137,
    color = 0,
    scale = 0.75,
    category = 41
}

Config.Peds = {
    {
        label = "Male Officer #1",
        model = "s_m_m_cop_01",
        pedComponents = {
            {id = 0, drawable = 3, texture = 0}, -- Head
            {id = 1, drawable = 1, texture = 0}, -- Beard
            {id = 2, drawable = 3, texture = 0}, -- Hair   
            {id = 3, drawable = 1, texture = 0}, -- Upper
            {id = 4, drawable = 0, texture = 0}, -- Lower
            {id = 5, drawable = 0, texture = 0}, -- Hand
            {id = 6, drawable = 1, texture = 0}, -- Feet
            {id = 7, drawable = 2, texture = 0}, -- Teeth
            {id = 8, drawable = 3, texture = 0}, -- Accessories
            {id = 9, drawable = 0, texture = 0}, -- Task
            {id = 10, drawable = 1, texture = 0}, -- Decals
            {id = 11, drawable = 1, texture = 0}, -- Torso
        }
    },
    {
        label = "Female Officer #1",
        model = "s_f_y_cop_01",
        pedComponents = {
            {id = 0, drawable = 2, texture = 0}, -- Head
            {id = 1, drawable = 0, texture = 0}, -- Beard
            {id = 2, drawable = 2, texture = 0}, -- Hair   
            {id = 3, drawable = 3, texture = 0}, -- Upper
            {id = 4, drawable = 1, texture = 0}, -- Lower
            -- {id = 5, drawable = 0, texture = 0}, -- Hand
            {id = 6, drawable = 1, texture = 0}, -- Feet
            {id = 7, drawable = 2, texture = 0}, -- Teeth
            {id = 8, drawable = 3, texture = 0}, -- Accessories
            -- {id = 9, drawable = 0, texture = 0}, -- Task
            {id = 10, drawable = 0, texture = 0}, -- Decals
            {id = 11, drawable = 0, texture = 0}, -- Torso
        },
    },
}

Config.AdminGroups = {
    "qbcore.admin",
    "qbcore.god",
    "god",
    "admin",
    "mod",
    "superadmin",
}

Config.TargetIcons = {
    frontdesk = "fas fa-shield-alt",
    stab_sticks = "fas fa-road-barrier",
    escort = "fas fa-people-pulling",
    handcuffs = "fas fa-handcuffs",
    grappler = "fas fa-road-barrier",
    objects = "fas fa-box",
    evidence_camera = "fas fa-camera",
    breathalyzer = "fas fa-vial",
    search = "fas fa-search",
    fingerprint_scanner = "fas fa-fingerprint",
    fines = "fas fa-money-bill-wave",
    shields = "fas fa-shield-alt",
    snakecam = "fas fa-camera",
    jail = "fas fa-lock",
    evidence_pickup = "fas fa-broom",
    id_card = "fas fa-id-card",
    vehicle_interact = "fas fa-car",
    locker = "fas fa-box",
}

Config.FrameworkSettings = {
    dirtyMoney = "DEFAULT",
    usableItemMetadata = function(item, data)
        if type(data) == "table" and data.metadata then return data.metadata end
        if type(item) == "table" and item.metadata then return item.metadata end
        if type(data) == "table" and data.info then return data.info end
        if type(item) == "table" and item.info then return item.info end
        print("^1ERROR: METADATA IS WRONGLY CONFIGURED, CHECK CONFIG.LUA:^0", item, data)
    end
}

Config.IsPlayerDead = function()
    if GetResourceState("wasabi_ambulance") == "started" then
        return exports.wasabi_ambulance:isPlayerDead()
    end
    return IsEntityDead(PlayerPedId())
end

Config.GiveKeys = function(vehicle, plate)
    -- Replace this line with your export / event to give keys for your vehicle.
end

Config.PoliceJobs = { -- You can use multiple departments with the same job, no need to add anything here if you don't want to.
    ["police"] = { -- The framework's job name, used in /setjob.
        label = "Police",
        maxLevel = 4, -- The leader's rank will be set to this level, ranks lower than the leader will be 0 through to one level below the leader.
    },
    ["sheriff"] = { -- The framework's job name, used in /setjob.
        label = "Blaine County Sheriff's Office",
        maxLevel = 2, -- The leader's rank will be set to this level, ranks lower than the leader will be 0 through to one level below the leader.
    },
}

Config.Jail = {
    enabled = true,
    maxJailTime = 120, -- The maximum amount of time a player can be jailed for.
}

Config.Fines = {
    enabled = true,
    maxFineAmount = 100000,
    viewFinesCommand = "fines",
}

-- Actions / Evidence

Config.Handcuffs = {
    item = {
        name = "handcuffs", -- The name of the item to use for the cuffs.
        required = true, -- Only set this to true if the item is required to use the cuffs.
    },
    allowResist = true,
    resistSkillCheck = {
        length = 5,
        availableSteps = {'easy', 'medium'},
        availableControls = {'w', 'a', 's', 'd'},
    },
    lockpickItem = "bobby_pins", -- set to nil (not "nil") to disable lockpicking of cuffs.
    lockpickRemoveChance = 100, -- The chance to remove the lockpick when lockpicking, if set to 100 then it will always remove the lockpick.
    skillCheck = {
        length = 5,
        availableSteps = {'easy', 'medium'},
        availableControls = {'w', 'a', 's', 'd'},
    },
}

Config.StabSticks = {
    enabled = true,
    item = {
        name = "stab_sticks", -- The name of the item to use for the stab sticks.
        required = true, -- Only set this to true if the item is required to use the stab sticks.
        remove = true, -- Only set this to true if the item is removed when the stab sticks are deployed.
    },
    renderDistance = 200.0, -- The distance at which the stab sticks will be rendered. Leave this alone please.
    burstDamage = 800.0, -- The damage to apply to the vehicle when a stab stick is deployed. Don't set this above 1000.0
    maxLength = 10, -- The maximum length of the stab sticks that can be deployed.
}

Config.Grappler = {
    enabled = true,
    item = {
        name = "grappler", -- The name of the item to use for the grappler.
        required = true, -- Only set this to true if the item is required to use the grappler.
        remove = true, -- Only set this to true if the item is removed when the grappler is deployed.
    },
    renderDistance = 100.0, -- The distance at which the grappler will be rendered. Leave this alone please.
}

Config.Evidence = {
    enabled = true,
    cameraItem = {
        name = "evidence_camera", -- The name of the item to use for the camera.
        required = true, -- Only set this to true if the item is required to use the camera.
    },
    breathalyzerItem = {
        name = "breathalyzer", -- The name of the item to use for the breathalyzer.
        required = true, -- Only set this to true if the item is required to use the breathalyzer.
    },
    fingerprintScannerItem = {
        name = "fingerprint_scanner", -- The name of the item to use for the fingerprint scanner.
        required = true, -- Only set this to true if the item is required to use the fingerprint scanner.
    },
    renderDistance = 25.0, -- The distance at which evidence will be rendered.
    reconstructRenderDistance = 100.0, -- The distance at which evidence will be rendered for the reconstructed scene.
    maxDisplayAmount = 3, -- The maximum amount of a group of evidence that can be displayed.
    queueInterval = 1, -- The interval at which shell casings will be added to the queue. Leave this at 1.
    evidenceGroupDistance = 2.0, -- The distance at which shell casings will be grouped together.
    maxFilesQuery = 20, -- The maximum amount of results to return from the database when searching for files.
    weaponGroups = {
        ["GROUP_HEAVY"] = {
            label = "Military-Grade Firearm",
            shellModel = `w_pi_singleshot_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_MG"] = {
            label = "Class-D Automatic Firearm",
            shellModel = `w_pi_singleshot_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_SNIPER"] = {
            label = "Class-D Sniper Rifle",
            shellModel = `w_pi_singleshot_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_SMG"] = {
            label = "Class-C Automatic Firearm",
            shellModel = `w_pi_singleshoth4_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_RIFLE"] = {
            label = "Class-C Semi-Automatic Rifle",
            shellModel = `w_pi_singleshot_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_SHOTGUN"] = {
            label = "Class-B Shotgun",
            shellModel = `w_sg_pumpshotgunh4_mag1`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
        ["GROUP_PISTOL"] = {
            label = "Class-B Semi-Automatic Pistol",
            shellModel = `w_pi_singleshoth4_shell`,
            shellRotation = vector3(0.0, 0.0, 0.0),
        },
    }
}

Config.Helmets = {
    EnableFlashlights = true, -- Set to false to disable flashlights 
    AllowedProps = {
        {
            up = 117,
            down = 116
        },
    }
}

Config.Bodycam = {
    item = {
        name = "police_bodycam", -- The name of the item to use for the camera.
        required = true, -- Only set this to true if the item is required to view the officer's bodycam.
    }
}

Config.Shields = {
    enabled = true,
    item = {
        name = "police_shield", -- The name of the item to use for the shield.
        required = true, -- Only set this to true if the item is required to use the shield.
        remove = true, -- Only set this to true if the item is removed when the shield is deployed.
    },
    Models = {
        [`prop_riot_shield`] = {
            Label = "Riot Shield",
            DefaultOffset = {vector3(0.0, 0.45, 0.05), vector3(180.0, -90.0, 0.0)},
            AimingOffset = {vector3(0.0, 0.35, 0.25), vector3(180.0, -90.0, 0.0)},
            Groups = {
                ["police"] = 0, 
            },
        },
        [`prop_ballistic_shield`] = {
            Label = "Police Shield",
            DefaultOffset = {vector3(-0.1, 0.45, 0.05), vector3(180.0, -90.0, 0.0)},
            AimingOffset = {vector3(-0.1, 0.35, 0.25), vector3(180.0, -90.0, 0.0)},
            Groups = {
                ["police"] = 0, 
            },
        },
    }
}

Config.Snakecam = {
    enabled = true,
    item = {
        name = "police_snakecam", -- The name of the item to use for the camera.
        required = true, -- Only set this to true if the item is required to use the camera.
    },
    MaxLength = 10.0,
    Controls = {
        up = 32,
        down = 33,

        look_up = 172,
        look_down = 173,
        look_left = 174,
        look_right = 175,

        stop_cam = 177
    }
}

Config.ObjectPlacement = {
    renderDistance = 100.0, -- The distance at which the object placement will be rendered. Leave this alone please.
    props = {
        {label = "Traffic Cone", model = `prop_roadcone02a`, image = "nui://pickle_policejob/nui/images/prop_roadcone02a.png"},
        {label = "Police Barrier", model = `prop_barrier_work05`, image = "nui://pickle_policejob/nui/images/prop_barrier_work05.png"},
        {label = "Construction Barrier #1", model = `prop_barrier_work06a`, image = "nui://pickle_policejob/nui/images/prop_barrier_work06a.png"},
        {label = "Construction Barrier #2", model = `prop_barrier_work06b`, image = "nui://pickle_policejob/nui/images/prop_barrier_work06b.png"},
        {label = "Police Tent", model = `prop_gazebo_02`, image = "nui://pickle_policejob/nui/images/prop_gazebo_02.png", targetZOffset = -1.0},
        {label = "Portable Light", model = `prop_worklight_03b`, image = "nui://pickle_policejob/nui/images/prop_worklight_03b.png"},
    }
}

-- Department / Computer

Config.Computer = {
    vehicleCommand = "pdterminal",
}

Config.PoliceArmory = {
    { 
        name = "weapon_pistol",
        count = 1,
        itemType = "weapon",
        price = 1000,
        maxCount = 1,
    },
    {
        name = "weapon_stungun",
        count = 1,
        itemType = "weapon",
        price = 0,
        maxCount = 1,
    },
    {
        name = "weapon_carbinerifle",
        count = 1,
        itemType = "weapon",
        price = 1000,
        maxCount = 1,
    },
    {
        name = "weapon_assaultrifle",
        count = 1,
        itemType = "weapon",
        price = 1000,
        maxCount = 1,
    },
}

Config.PoliceGarageTypes = {
    cars = {
        label = "Vehicle Garage",
        cameraOffset = {
            coords = vector3(0.0, -6.0, 1.75), -- Where to set the camera.
            rotation = vector3(-20.0, 0.0, 0.0), -- Z does nothing, as that is the heading. X is up/down, Y is tilt left/right.
        }
    },
    boats = {
        label = "Boat Dock",
        cameraOffset = {
            coords = vector3(0.0, -6.0, 1.75), -- Where to set the camera.
            rotation = vector3(-20.0, 0.0, 0.0), -- Z does nothing, as that is the heading. X is up/down, Y is tilt left/right.
        }
    },
    aircraft = {
        label = "Aircraft Hangar",
        cameraOffset = {
            coords = vector3(0.0, -8.0, 2.75), -- Where to set the camera.
            rotation = vector3(-25.0, 0.0, 0.0), -- Z does nothing, as that is the heading. X is up/down, Y is tilt left/right.
        }
    },
}

Config.PoliceGarage = {
    -- CARS
    {
        garageType = "cars",
        label = "Crown Victory",
        image = "https://docs.fivem.net/vehicles/police.webp",
        model = `police`,
        price = 1000,
    },
    {
        garageType = "cars",
        label = "Police Interceptor",
        image = "https://docs.fivem.net/vehicles/police2.webp",
        model = `police2`,
    },
    {
        garageType = "cars",
        label = "Police SUV",
        image = "https://docs.fivem.net/vehicles/police3.webp",
        model = `police3`,
    },
    {
        garageType = "cars",
        label = "Police SUV II",
        image = "https://docs.fivem.net/vehicles/police4.webp",
        model = `police4`,
    },
    {
        garageType = "cars",
        label = "Police SUV III",
        image = "https://docs.fivem.net/vehicles/police5.webp",
        model = `police5`,
    },
    {
        garageType = "cars",
        label = "Police Bus",
        image = "https://docs.fivem.net/vehicles/pbus.webp",
        model = `pbus`,
    },
    {
        garageType = "cars",
        label = "S.W.A.T. Truck",
        image = "https://docs.fivem.net/vehicles/riot.webp",
        model = `riot`,
    },
    {
        garageType = "cars",
        label = "Riot Truck",
        image = "https://docs.fivem.net/vehicles/riot2.webp",
        model = `riot2`,
    },
    -- AIRCRAFT
    {
        garageType = "aircraft",
        label = "Police Helicopter",
        image = "https://docs.fivem.net/vehicles/polmav.webp",
        model = `polmav`,
    },
    -- BOATS
}

Config.Frontdesk = {
    requestOfficer = {
        enabled = false,
    },
    applyForDepartment = {
        enabled = false,
    },
    fileReport = {
        enabled = false,
    },
}

Config.Locker = {
    maxWeight = 100000,
    slots = 100,
}

Config.CurrencyItems = {
    -- These are the items that will be used for images from your inventory.
    ["money"] = "money",
    ["dirty_money"] = "black_money",
}

-- Integrations

Config.Integrations = {
    fines = {
        onFineIssued = function(id,source, target, title, description, amount)
            -- Called when a fine is issued.
        end,
        onFinePaid = function(id, source, issuingIdentifier, title, description, amount)
            -- Called when a fine is paid.
        end,
        onFineRemoved = function(id, source, issuingIdentifier, title, description, amount)
            -- Called when a fine is removed.
        end,
    },
    jail = {
        openJailMenu = function()
            -- Replace this with your export / event to open the jail menu. (Client-side ONLY)
            if GetResourceState("pickle_prisons") == "started" then
                ExecuteCommand("jailmenu")
                return true -- Return true to prevent the default jail menu from being opened.
            elseif GetResourceState("DHS-PrisonSim") == "started" then
                exports['DHS-PrisonSim']:OpenConvoyMenu()
                return true
            end
            return false
        end,
        jailPlayer = function(source, time, reason)
            -- Replace this with your export / event to jail a player. (Server-side ONLY)
            if GetResourceState("pickle_prisons") == "started" then
                -- client side menu
            end
        end,
    },
    duty = {
        client = function(departmentId, isOnDuty, report)
        end,
        server = function(source, departmentId, isOnDuty, report)
        end,
    },
    inventory = {
        OpenNearbyInventory = function()
            -- Replace this with your export / event to open the nearby inventory. (Client-side ONLY)
        end,
    }
}