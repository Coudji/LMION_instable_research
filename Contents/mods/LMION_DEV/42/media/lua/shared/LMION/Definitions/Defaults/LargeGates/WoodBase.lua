return {
    defaultId = "LargeGates.Wood.Base",
    defaults = {
        doorType = "LargeGate", materialType = "Wood_Solid", doorSound = "WoodGate", thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails" },
        durability = { worldHealth = 650, health = 400, skillBaseHealth = 300 },
        construction = {
            timedAction = "BuildWallHammer", skill = { Woodwork = 4 }, time = 180, xp = 30, tools = { { tag = "base:hammer" } },
            materials = { { item = "Base.Plank", amount = 8 }, { item = "Base.Nails", amount = 8 }, { item = "Base.Hinge", amount = 4 }, { item = "Base.Doorknob", amount = 2 } },
        },
        pickup = {
            skill = { Woodwork = 2 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BeginRemoveBarricadePlankCrowbar", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { count = 2, weight = 18, itemTemplate = "Base.LMION_{entityName}{leaf}_Part{partIndex}" },
        },
        replacement = {
            packages = 2, tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "Hammering", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
