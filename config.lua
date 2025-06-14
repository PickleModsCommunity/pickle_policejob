Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.ImageDirectory = "nui://ox_inventory/web/images/"
Config.WeaponsAreItems = true -- This enables the use of weapons as items. If set to false, weapons will be treated as items and not as weapons.

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

Config.Departments = {
    [11] = {
        -- Blaine County Sheriff's Office
        label = "Blaine County Sheriff's Office",
        location = {
            coords = vector3(1852.9951, 3688.9219, 33.2671),
            heading = 206.4117,
        },
        members = {
            {
                rankId = 1,
                identifier = "char1:7817bde6206cb72577821aa3369e8d15f688138a",
                name = "Joe Biden",
                totalDutyTime = 0,
                recentDutyLogs = {},
                permissions = {"Air Certified", "Rifle Certified"}
            }
        },
        permissions = Config.DefaultDepartment.permissions,
        ranks = Config.DefaultDepartment.ranks,
        outfits = {
            {
                name = "Cadet Uniform",
                gender = "male",
                outfit = {}
            }
        },
        entities = {
            {
                id = 1,
                type = "frontdesk",
                location = {
                    coords = vector3(1852.9951, 3688.9219, 33.2671),
                    heading = 208.5152,
                },
                permissions = {},
                ped = "s_m_y_sheriff_01",
            },
            {
                id = 2,
                type = "frontdesk",
                location = {
                    coords = vector3(1856.8533, 3689.6973, 33.2670),
                    heading = 214.1353,
                },
                permissions = {"SWAT"},
                ped = "s_m_y_sheriff_01",
            }
        }
    }
}