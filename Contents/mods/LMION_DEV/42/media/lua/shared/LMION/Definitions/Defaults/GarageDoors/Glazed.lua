return {
    defaultId = "GarageDoors.Glazed",
    defaults = {
        doorType = "Garage", materialType = "Metal_Light", doorSound = "GarageDoor", thumpSound = "ZombieThumpGarageDoor",
        engineMaterials = { "MetalPlates", "MetalBars", "Glass" },
        durability = { worldHealth = 1000, health = 500, skillBaseHealth = 350 },
        construction = {
            category = "Welding", variantGroup = "GarageDoors.Glazed", timedAction = "BuildWallMetal",
            skill = { MetalWelding = 6 }, time = 200, xp = 50, tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = { perStep = 1, step = 3, max = 10 } },
                { item = "Base.SmallSheetMetal", amount = { perWidth = 2 } },
                { item = "Base.GlassPanel", amount = { perWidth = 1 } },
                { anyOf = { "Base.MetalBar", "Base.IronBar" }, amount = { perWidth = 1 }, widthInput = true },
                { item = "Base.Hinge", amount = { perWidth = 2 } },
                { item = "Base.WeldingRods", uses = { perStep = 2, step = 3, max = 20 } },
            },
        },
        pickup = {
            skill = { MetalWelding = 3 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { weight = 20, itemTemplate = "Base.LMION_{entityName}_Part{roleIndex}" },
        },
        replacement = {
            tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
