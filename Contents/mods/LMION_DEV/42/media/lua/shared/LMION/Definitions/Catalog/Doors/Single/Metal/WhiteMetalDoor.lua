return {
    definitionId = "Doors.Metal.WhiteMetalDoor",
    entity = "Base.WhiteMetalDoor",
    inherits = "Doors.Metal.Base",

    construction = {
        skill = { MetalWelding = 5 },
        unlock = { skill = "MetalWelding", level = 5 },
        variantGroup = "Doors.Metal.Plain",
        variantOrder = 30,
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_57",
            open = "fixtures_doors_01_59",
        },
        W = {
            closed = "fixtures_doors_01_56",
            open = "fixtures_doors_01_58",
        },
    },
}
