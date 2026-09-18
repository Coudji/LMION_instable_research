return {
    defaultId = "LargeGates.Metal.Wire",
    defaults = {
        doorType = "LargeGate", materialType = "Metal_Light", doorSound = "MetalGate", thumpSound = "ZombieThumpChainlinkFence",
        engineMaterials = { "MetalPipe", "MetalWire" },
        durability = { worldHealth = 850, health = 400, skillBaseHealth = 275 },
        construction = {
            category = "Welding",
            timedAction = "BuildWallMetal", skill = { MetalWelding = 5 }, time = 220, xp = 40, tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 10 }, { item = "Base.MetalPipe", amount = 8 }, { item = "Base.Wire", uses = 4 },
                { item = "Base.Hinge", amount = 4 }, { item = "Base.ScrapMetal", amount = 2 }, { item = "Base.WeldingRods", uses = 10 },
            },
        },
        pickup = {
            skill = { MetalWelding = 2 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { count = 2, weight = 15, itemTemplate = "Base.LMION_{entityName}{leaf}_Part{partIndex}" },
        },
        replacement = {
            packages = 2, tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
