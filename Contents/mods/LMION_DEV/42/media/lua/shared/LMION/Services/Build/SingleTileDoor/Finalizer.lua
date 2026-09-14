local BuiltDoor = require "LMION/PZ/BuiltDoor"
local CanonicalDoor = require "LMION/Runtime/CanonicalDoor"
local ConstructionDurability = require "LMION/Services/Build/ConstructionDurability"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local DoorObject = require "LMION/PZ/DoorObject"

local SingleTileDoorFinalizer = {}

function SingleTileDoorFinalizer.finalize(square, profile, craftRecipe, character)
    if type(profile) ~= "table"
        or type(profile.definition) ~= "table"
        or type(profile.entityId) ~= "string" then
        return nil
    end

    local object = BuiltDoor.findByEntityId(square, profile.entityId)
    if object == nil then
        print(string.format(
            "[LMION:DEV] Single-tile Build finalize failed: definition=%s member=%s entity=%s reason=no-door",
            tostring(profile.definitionId),
            tostring(profile.member),
            tostring(profile.entityId)
        ))
        return nil
    end

    print(string.format(
        "[LMION:DEV] Single-tile Build finalizing: definition=%s type=%s member=%s entity=%s representation=%s",
        tostring(profile.definitionId),
        tostring(profile.doorType),
        tostring(profile.member),
        tostring(profile.entityId),
        tostring(DoorObject.getRepresentation(object))
    ))

    local door = CanonicalDoor.ensure(object, { preserveLockState = false })
    if door == nil then
        print(string.format(
            "[LMION:DEV] Single-tile Build finalize failed: definition=%s member=%s reason=canonicalization",
            tostring(profile.definitionId),
            tostring(profile.member)
        ))
        return nil
    end

    local maxHealth = ConstructionDurability.getEffectiveMaxHealth(
        profile.definition,
        craftRecipe,
        character
    )
    if maxHealth ~= nil then
        DoorDurability.setEffectiveMaxHealth(door, maxHealth)
        DoorDurability.setHealth(door, maxHealth)
    end

    if isServer() and door.transmitCompleteItemToClients ~= nil then
        door:transmitCompleteItemToClients()
    end

    print(string.format(
        "[LMION:DEV] Single-tile Build finalized: definition=%s type=%s member=%s representation=%s health=%s max=%s",
        tostring(profile.definitionId),
        tostring(profile.doorType),
        tostring(profile.member),
        tostring(DoorObject.getRepresentation(door)),
        tostring(DoorDurability.getHealth(door)),
        tostring(DoorDurability.getEffectiveMaxHealth(door))
    ))

    return door
end

return SingleTileDoorFinalizer
