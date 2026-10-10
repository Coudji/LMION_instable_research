return {
    definitionId = "Doors.Metal.MetalDoorLvl2",
    entity = "Base.MetalDoorLvl2",
    inherits = "Doors.Metal.Base",

    construction = {
        skill = { MetalWelding = 3 },
        unlock = { skill = "MetalWelding", level = 5 },
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_53",
            open = "fixtures_doors_01_55",
        },
        W = {
            closed = "fixtures_doors_01_52",
            open = "fixtures_doors_01_54",
        },
    },
}
