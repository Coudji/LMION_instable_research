return {
    defaultId = "LargeGates.Wood.Hard",
    defaults = {
        doorType = "LargeGate", materialType = "Wood_Solid", doorSound = "WoodGate", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 750, health = 500, skillBaseHealth = 350 },
        construction = {
            timedAction = "BuildWallHammer", skill = { Woodwork = 7 }, time = 240, xp = 60,
            tools = { { tag = "base:hammer" }, { tag = "base:screwdriver" } },
            materials = {
                { item = "Base.Plank", amount = 10 }, { item = "Base.Nails", amount = 10 }, { item = "Base.Screws", amount = 8 },
                { item = "Base.Hinge", amount = 4 }, { item = "Base.Doorknob", amount = 2 },
            },
        },
        pickup = {
            skill = { Woodwork = 3 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BeginRemoveBarricadePlankCrowbar", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { count = 2, weight = 22, itemTemplate = "Base.LMION_{entityName}{leaf}_Part{partIndex}" },
        },
        replacement = {
            packages = 2, tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "Hammering", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
