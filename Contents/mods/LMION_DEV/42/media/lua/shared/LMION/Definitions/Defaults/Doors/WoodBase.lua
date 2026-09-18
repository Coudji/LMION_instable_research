return {
    defaultId = "Doors.Wood.Base",

    defaults = {
        doorType = "Simple",
        materialType = "Wood_Solid",
        doorSound = "WoodDoor",
        thumpSound = "ZombieThumpWood",
        engineMaterials = { "Wood", "Nails" },

        durability = { worldHealth = 500, health = 300, skillBaseHealth = 200 },

        construction = {
            timedAction = "BuildWallHammer",
            skill = { Woodwork = 5 },
            time = 120,
            xp = 25,
            tools = { { tag = "base:hammer" } },
            materials = {
                { item = "Base.Plank", amount = 4 },
                { item = "Base.Nails", amount = 4 },
                { item = "Base.Hinge", amount = 2 },
                { item = "Base.Doorknob", amount = 1 },
            },
        },

        pickup = {
            skill = { Woodwork = 2 },
            tools = { { tag = "base:screwdriver" } },
            action = { time = 100, sound = "Dismantle", soundIsWav = true, animation = "LMION_ScrewdriverHinge" },
            breakChance = 0,
            packages = { count = 1, weight = 15, itemTemplate = "Base.LMION_{entityName}" },
        },

        replacement = {
            packages = 1,
            tools = { { tag = "base:screwdriver" } },
            action = { time = 100, sound = "Dismantle", soundIsWav = true, animation = "LMION_ScrewdriverHinge" },
            materials = {},
        },
    },
}
