Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"
Config.WeaponsAreItems = true -- This enables the use of weapons as items. If set to false, weapons will be treated as items and not as weapons.
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
}

Config.FrameworkSettings = {
    dirtyMoney = "DEFAULT",
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

Config.Currency = {
    currency = "USD",
    countryCode = "en-US",
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
        price = 1000,
        maxCount = 1,
    },
    {
        name = "weapon_carbinerifle",
        count = 1,
        itemType = "weapon",
        price = 1000,
        maxCount = 1,
    },
}

Config.PoliceGarage = {
    {
        label = "Crown Victoria",
        image = "/nui/images/LSPD.webp",
        model = -12300341,
    },
    {
        label = "Police Interceptor",
        image = "/nui/images/LSPD.webp",
        model = -12300342,
    },
    {
        label = "Police SUV",
        image = "/nui/images/LSPD.webp",
        model = -12300343,
    },
    {
        label = "Police SUV II",
        image = "/nui/images/LSPD.webp",
        model = -12300344,
    },
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
    duty = {
        client = function(departmentId, isOnDuty, report)
        end,
        server = function(source, departmentId, isOnDuty, report)
        end,
    },
}

Config.DocumentTemplates = {
    -- Feel free to change these as you wish, but note we will not support any issues that arise from your changes as this is considered a customisation.

    -- SHARED VARIABLES:
    -- {department} - The name of the officer's department.
    -- {name} - The name of the officer.
    -- {rank} - The rank of the officer.

    ["shift_report"] = {
        -- AVAILABLE VARIABLES:
        -- {shiftStart} - The start date & time of the shift.
        -- {shiftEnd} - The end date & time of the shift.
        -- {duration} - The duration of the shift.
        title = "{department}", -- The top title of the document.
        subtitle = "SHIFT REPORT", -- The subtitle of the document.
        header = {
            showImage = true, -- Whether to show the image of the department at the top of the document.
            leftInfo = {
                { label = "<span class='font-bold'>{name}</span>" },
                { label = "{rank}" },
            },
            rightInfo = {
                { label = "<span class='font-bold'>Shift Start</span>" },
                { label = "{shiftStart}" },
                { label = "<span class='font-bold'>Shift End</span>" },
                { label = "{shiftEnd}" },
                { label = "<span class='font-bold'>Shift Duration</span>" },
                { label = "{duration}" },
            },
        },
        content = {
            { label = "<span class='font-bold'>{name}</span>" },
            { label = "{rank}" },
        }
    }
}