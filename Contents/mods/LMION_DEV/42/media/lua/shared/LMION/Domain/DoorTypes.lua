local DoorTypes = {}

local TYPE_ORDER = {
    "Simple",
    "Paired",
    "FenceGate",
    "Sliding",
    "LargeGate",
    "Garage",
}

local TYPES = {
    Simple = { frameRequirement = "standard" },
    Paired = { frameRequirement = "paired" },
    FenceGate = { frameRequirement = "none" },
    Sliding = { frameRequirement = "none" },
    LargeGate = { frameRequirement = "none" },
    Garage = { frameRequirement = "none" },
}

function DoorTypes.isSupported(doorType)
    return TYPES[doorType] ~= nil
end

function DoorTypes.getNames()
    local names = {}

    for index = 1, #TYPE_ORDER do
        names[index] = TYPE_ORDER[index]
    end

    return names
end

function DoorTypes.getFrameRequirement(doorType)
    local definition = TYPES[doorType]

    if definition == nil then
        return nil
    end

    return definition.frameRequirement
end

return DoorTypes
