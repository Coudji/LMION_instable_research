return {
    defaultId = "FenceGates.Metal.Wire",
    defaults = {
        doorType = "FenceGate", materialType = "Metal_Light", doorSound = "MetalGate", thumpSound = "ZombieThumpChainlinkFence",
        engineMaterials = { "MetalPipe", "MetalWire" },
        durability = { worldHealth = 600, health = 300, skillBaseHealth = 225 },
        construction = {
            timedAction = "BuildWallMetal", skill = { MetalWelding = 3 }, time = 110, xp = 15,
            tools = { { tag = "base:weldingmask" } },
            materials = {
                { item = "Base.BlowTorch", uses = 4 }, { item = "Base.MetalPipe", amount = 4 }, { item = "Base.Wire", uses = 2 },
                { item = "Base.Hinge", amount = 2 }, { item = "Base.ScrapMetal", amount = 1 }, { item = "Base.WeldingRods", uses = 4 },
            },
        },
        pickup = {
            skill = { MetalWelding = 1 }, tools = { { tag = "base:crowbar" } },
            action = { time = 150, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_CrowbarPickupLow" },
            breakChance = 0, packages = { count = 1, weight = 12, itemTemplate = "Base.LMION_{entityName}" },
        },
        replacement = {
            packages = 1, tools = { { tag = "base:hammer" } },
            action = { time = 75, sound = "BuildMetalStructureSmall", soundIsWav = true, animation = "LMION_HammerPlace" }, materials = {},
        },
    },
}
