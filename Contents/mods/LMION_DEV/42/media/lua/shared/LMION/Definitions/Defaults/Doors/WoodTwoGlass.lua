return {
    defaultId = "Doors.Wood.TwoGlass",
    defaults = {
        doorType = "Simple", materialType = "Wood_Solid", doorSound = "MetalDoor", thumpSound = "ZombieThumpWindow",
        engineMaterials = { "Wood", "Nails", "Screws" },
        durability = { worldHealth = 500, health = 350, skillBaseHealth = 225 },
        construction = {
            category = "Carpentry", variantGroup = "Doors.Wood.TwoGlass", timedAction = "BuildWallHammer",
            skill = { Woodwork = 7 }, time = 180, xp = 45,
            tools = { { tag = "base:hammer", flags = { "Prop1", "MayDegradeVeryLight" } }, { tag = "base:screwdriver" } },
            materials = {
                { item = "Base.Plank", amount = 4 }, { item = "Base.Nails", amount = 4 }, { item = "Base.Hinge", amount = 2 },
                { item = "Base.Screws", amount = 4 }, { item = "Base.Doorknob", amount = 1 }, { item = "Base.GlassPanel", amount = 2 },
            },
        },
        pickup = {
            skill = { Woodwork = 3 }, tools = { { tag = "base:screwdriver" } },
            action = { time = 100, sound = "Dismantle", soundIsWav = true, animation = "LMION_ScrewdriverHinge" },
            breakChance = 0, packages = { count = 1, weight = 16, itemTemplate = "Base.LMION_{entityName}" },
        },
        replacement = {
            packages = 1, tools = { { tag = "base:screwdriver" } },
            action = { time = 100, sound = "Dismantle", soundIsWav = true, animation = "LMION_ScrewdriverHinge" }, materials = {},
        },
    },
}
