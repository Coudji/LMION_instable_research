local BuiltDoor = require "LMION/PZ/BuiltDoor"
local CanonicalDoor = require "LMION/Runtime/CanonicalDoor"
local ConstructionDurability = require "LMION/Services/Build/ConstructionDurability"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local DoorObject = require "LMION/PZ/DoorObject"

local SimpleDoorFinalizer = {}

function SimpleDoorFinalizer.finalize(square, definition, craftRecipe, character)
    if type(definition) ~= "table" or type(definition.entity) ~= "string" then
        return nil
    end

    local object = BuiltDoor.findByEntityId(square, definition.entity)
    if object == nil then
        print(string.format(
            "[LMION:DEV] Simple Build finalize failed: definition=%s entity=%s reason=no-door",
            tostring(definition.definitionId),
            tostring(definition.entity)
        ))
        return nil
    end

    print(string.format(
        "[LMION:DEV] Simple Build finalizing: definition=%s entity=%s representation=%s",
        tostring(definition.definitionId),
        tostring(definition.entity),
        tostring(DoorObject.getRepresentation(object))
    ))

    local door = CanonicalDoor.ensure(object, { preserveLockState = false })
    if door == nil then
        print(string.format(
            "[LMION:DEV] Simple Build finalize failed: definition=%s reason=canonicalization",
            tostring(definition.definitionId)
        ))
        return nil
    end

    local maxHealth = ConstructionDurability.getEffectiveMaxHealth(definition, craftRecipe, character)
    if maxHealth ~= nil then
        DoorDurability.setEffectiveMaxHealth(door, maxHealth)
        DoorDurability.setHealth(door, maxHealth)
    end

    if isServer() and door.transmitCompleteItemToClients ~= nil then
        door:transmitCompleteItemToClients()
    end

    print(string.format(
        "[LMION:DEV] Simple Build finalized: definition=%s representation=%s health=%s max=%s",
        tostring(definition.definitionId),
        tostring(DoorObject.getRepresentation(door)),
        tostring(DoorDurability.getHealth(door)),
        tostring(DoorDurability.getEffectiveMaxHealth(door))
    ))

    return door
end

return SimpleDoorFinalizer
