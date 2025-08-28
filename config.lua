Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"
Config.WeaponsAreItems = true -- This enables the use of weapons as items. If set to false, weapons will be treated as items and not as weapons.
Config.Finance = {
    deductSalaryFromDepartment = true, -- When true, the salary will be deducted from the department's funds - if it is too much it will not pay. False pays out without deducting.
    maxRankSalary = 100000, -- The maximum salary a rank can have.
    salarySchedule = "*/15 * * * *", -- The CRON schedule at which the salary will be paid. Default is every 15 minutes.
    maxTransactions = 100, -- The maximum number of transactions to store per department.
}

Config.Peds = {
    {
        label = "Male Officer #1",
        model = "s_m_m_cop_01",
    },
    {
        label = "Female Officer #1",
        model = "s_f_y_cop_01",
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

Config.Photos = {
    url = "https://fmapi.net/api/v2/image?apiKey=vX7G4UCDJLUSm19U1DGSdvUUpEiOSERv", -- By default, uses discord to host images.
    uploadProtocol = 'file',
    ResponseHandler = function(resp) -- Return URL from response.
       return resp.data.url
    end,
}

Config.VoiceTarget = 30 -- The channel to use for voice syncing while viewing a bodycam. Set to -1 to disable.

Config.IsPlayerDead = function()
    if GetResourceState("wasabi_ambulance") == "started" then
        return exports.wasabi_ambulance:isPlayerDead()
    end
    return IsEntityDead(PlayerPedId())
end

Config.GiveKeys = function(vehicle, plate)
    -- Replace this line with your export / event to give keys for your vehicle.
end

Config.Currency = {
    currency = "USD",
    countryCode = "en-US",
}

Config.DefaultJob = { name = "unemployed", level = 0 } -- The job to set players to when they clock off-duty.

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
    maxJailTime = 120, -- The maximum amount of time a player can be jailed for.
}

Config.Fines = {
    maxFineAmount = 100000,
    viewFinesCommand = "fines",
}

Config.StabSticks = {
    renderDistance = 200.0, -- The distance at which the stab sticks will be rendered. Leave this alone please.
    burstDamage = 800.0, -- The damage to apply to the vehicle when a stab stick is deployed. Don't set this above 1000.0
    maxLength = 10, -- The maximum length of the stab sticks that can be deployed.
}

Config.Grappler = {
    enabled = true,
    renderDistance = 100.0, -- The distance at which the grappler will be rendered. Leave this alone please.
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

Config.Computer = {
    vehicleCommand = "pdterminal",
}

Config.Evidence = {
    enabled = true,
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
    RequiredItem = "police_bodycam",
}

Config.Shields = {
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

Config.CurrencyItems = {
    -- These are the items that will be used for images from your inventory.
    ["money"] = "money",
    ["dirty_money"] = "black_money",
}

Config.DefaultDepartment = {
    permissions = { -- These are the default selectable permissions that will be used for the department.
        ["Air Certified"] = {
            managingRankIds = {2, 3},
        },
        ["Rifle Certified"] = {
            managingRankIds = {2, 3},
        },
        ["Field Training Officer"] = {
            managingRankIds = {2, 3},
        },
    },
    ranks = { -- Each rankId must be unique, if you break this and make a ticket I'm crashing out - just let the chief manage the ranks in-game.
        {
            rankId = 1,
            label = "Chief",
        },
        {
            rankId = 2,
            label = "Lieutenant",
        },
        {
            rankId = 3,
            managingRankIds = {2},
            label = "Sergeant",
        },
        {
            rankId = 4,
            managingRankIds = {2, 3},
            label = "Officer",
        },
        {
            rankId = 5,
            managingRankIds = {2, 3},
            label = "Recruit",
        },
    }
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