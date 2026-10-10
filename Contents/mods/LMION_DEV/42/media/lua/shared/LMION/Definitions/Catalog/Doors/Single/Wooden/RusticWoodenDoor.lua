return {
    definitionId = "Doors.Wood.RusticWoodenDoor",
    entity = "Base.RusticWoodenDoor",
    inherits = "Doors.Wood.Base",

    construction = {
        unlock = { skill = "Woodwork", level = 5 },
        variantGroup = "Doors.Wood.Solid",
    },

    geometry = {
        N = {
            closed = "fixtures_doors_01_9",
            open = "fixtures_doors_01_11",
        },
        W = {
            closed = "fixtures_doors_01_8",
            open = "fixtures_doors_01_10",
        },
    },
}
