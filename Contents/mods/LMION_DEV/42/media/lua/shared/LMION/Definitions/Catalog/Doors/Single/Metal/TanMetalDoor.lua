return {
    definitionId = "Doors.Metal.TanMetalDoor",
    entity = "Base.TanMetalDoor",
    inherits = "Doors.Metal.Base",

    construction = {
        skill = { MetalWelding = 5 },
        unlock = { skill = "MetalWelding", level = 5 },
        variantGroup = "Doors.Metal.Plain",
        variantOrder = 20,
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_65",
            open = "fixtures_doors_01_67",
        },
        W = {
            closed = "fixtures_doors_01_64",
            open = "fixtures_doors_01_66",
        },
    },
}
