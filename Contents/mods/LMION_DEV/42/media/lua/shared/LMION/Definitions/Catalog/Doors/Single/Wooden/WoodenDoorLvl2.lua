return {
    definitionId = "Doors.Wood.WoodenDoorLvl2",
    entity = "Base.WoodenDoorLvl2",
    inherits = "Doors.Wood.Base",

    construction = {
        unlock = { skill = "Woodwork", level = 5 },
        variantGroup = "Doors.Wood.Solid",
    },

    geometry = {
        N = {
            closed = "carpentry_01_53",
            open = "carpentry_01_55",
        },
        W = {
            closed = "carpentry_01_52",
            open = "carpentry_01_54",
        },
    },
}
