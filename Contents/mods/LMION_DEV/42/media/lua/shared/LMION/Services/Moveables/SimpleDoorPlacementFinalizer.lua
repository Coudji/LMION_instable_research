local CanonicalDoor = require "LMION/Runtime/CanonicalDoor"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local DoorObject = require "LMION/PZ/DoorObject"
local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"
local PlacedDoor = require "LMION/PZ/PlacedDoor"

local SimpleDoorPlacementFinalizer = {}

function SimpleDoorPlacementFinalizer.finalize(square, placedObject, item, spriteName, definitionId)
    local door = DoorObject.isDoor(placedObject) and placedObject
        or PlacedDoor.findBySprite(square, spriteName)

    if door == nil then
        print(string.format(
            "[LMION:DEV] Simple placement finalize failed: definition=%s sprite=%s reason=no-door",
            tostring(definitionId),
            tostring(spriteName)
        ))
        return nil
    end

    local canonical = CanonicalDoor.ensure(door)
    if canonical == nil then
        print(string.format(
            "[LMION:DEV] Simple placement finalize failed: definition=%s sprite=%s reason=canonicalization",
            tostring(definitionId),
            tostring(spriteName)
        ))
        return nil
    end

    local state = DoorTransportState.readFromItem(item)
    if state ~= nil then
        if state.maxHealth ~= nil then
            DoorDurability.restoreEffectiveMaxHealth(
                canonical,
                state.maxHealth,
                state.maxWasLogical == true
            )
        end

        if state.health ~= nil then
            DoorDurability.setHealth(canonical, state.health)
        end
    end

    print(string.format(
        "[LMION:DEV] Simple placement finalized: definition=%s sprite=%s health=%s max=%s",
        tostring(definitionId),
        tostring(spriteName),
        tostring(state and state.health or nil),
        tostring(state and state.maxHealth or nil)
    ))

    return canonical
end

return SimpleDoorPlacementFinalizer
