return {
    defaultId = "FenceGates.Wood.Hard",
    defaults = {
        doorType = "FenceGate", materialType = "Wood_Solid", doorSound = "WoodGate", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 600, health = 400, skillBaseHealth = 275 },
        construction = {
            timedAction = "BuildWallHammer", skill = { Woodwork = 5 }, time = 150, xp = 30,
            tools = { { tag = "base:hammer" }, { tag = "base:screwdriver" } },
            materials = {
                { item = "Base.Plank", amount = 5 }, { item = "Base.Nails", amount = 5 }, { item = "Base.Screws", amount = 4 },
                { item = "Base.Hinge", amount = 2 }, { item = "Base.Doorknob", amount = 1 },
            },
        },
        pickup = {
            skill = { Woodwork = 2 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BeginRemoveBarricadePlankCrowbar", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { count = 1, weight = 18, itemTemplate = "Base.LMION_{entityName}" },
        },
        replacement = {
            packages = 1, tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "Hammering", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
