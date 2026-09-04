local DoorObject = {}

function DoorObject.isIsoDoor(object)
    return object ~= nil and instanceof(object, "IsoDoor")
end

function DoorObject.isThumpableDoor(object)
    return object ~= nil
        and instanceof(object, "IsoThumpable")
        and object.isDoor ~= nil
        and object:isDoor()
end

function DoorObject.isDoor(object)
    return DoorObject.isIsoDoor(object) or DoorObject.isThumpableDoor(object)
end

function DoorObject.getRepresentation(object)
    if DoorObject.isIsoDoor(object) then
        return "IsoDoor"
    end

    if DoorObject.isThumpableDoor(object) then
        return "IsoThumpable"
    end

    return nil
end

function DoorObject.getNorth(object)
    if not DoorObject.isDoor(object) or object.getNorth == nil then
        return nil
    end

    return object:getNorth()
end

function DoorObject.getFacing(object)
    local north = DoorObject.getNorth(object)

    if north == nil then
        return nil
    end

    if north then
        return "N"
    end

    return "W"
end

return DoorObject
