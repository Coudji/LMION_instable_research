local DoorObject = require "LMION/PZ/DoorObject"
local DoorState = require "LMION/Runtime/DoorState"

local CanonicalDoor = {}

local function recreateGameEntity(object)
    if object == nil
        or GameEntityFactory == nil
        or GameEntityFactory.CreateIsoEntityFromCellLoading == nil then
        return
    end

    local properties = object:getProperties()
    if properties ~= nil and properties:has(IsoFlagType.EntityScript) then
        GameEntityFactory.CreateIsoEntityFromCellLoading(object)
    end
end

local function createIsoDoor(square, sprite, north)
    if IsoDoor == nil or IsoDoor.new == nil then
        return nil
    end

    return IsoDoor.new(getCell(), square, sprite, north)
end

function CanonicalDoor.ensure(object, options)
    if DoorObject.isIsoDoor(object) then
        return object
    end

    if not DoorObject.isThumpableDoor(object) then
        return nil
    end

    options = options or {}

    local square = object:getSquare()
    local sprite = object:getSprite()
    local north = DoorObject.getNorth(object)

    if square == nil or sprite == nil or north == nil then
        print("[LMION:DEV] canonical door failed: incomplete IsoThumpable source")
        return nil
    end

    local state = DoorState.capture(object)
    if state == nil then
        print("[LMION:DEV] canonical door failed: source state capture returned nil")
        return nil
    end

    if options.preserveLockState == false then
        state.locked = false
        state.lockedByKey = false
    end

    local door = createIsoDoor(square, sprite, north)
    if door == nil then
        print("[LMION:DEV] canonical door failed: IsoDoor creation returned nil")
        return nil
    end

    if object.getName ~= nil and door.setName ~= nil then
        local objectName = object:getName()
        if objectName ~= nil then
            door:setName(objectName)
        end
    end

    DoorState.restore(door, state)
    recreateGameEntity(door)

    square:AddSpecialObject(door)
    square:transmitRemoveItemFromSquare(object)

    print(string.format(
        "[LMION:DEV] canonical door ready: %s facing=%s",
        tostring(DoorObject.getRepresentation(door)),
        tostring(DoorObject.getFacing(door))
    ))

    return door
end

return CanonicalDoor
