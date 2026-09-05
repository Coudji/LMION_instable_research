local BuiltLargeGatePart = require "LMION/PZ/BuiltLargeGatePart"
local CanonicalDoor = require "LMION/Runtime/CanonicalDoor"
local ConstructionDurability = require "LMION/Services/Build/ConstructionDurability"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local DoorObject = require "LMION/PZ/DoorObject"

local LargeGateFinalizer = {}

local function applyGeometry(door, profile, segment)
    local geometry = profile.definition.geometry
    local part = geometry[segment.facing][profile.leaf][segment.partIndex]
    local closedSprite = part and getSprite(part.closed) or nil
    local openSprite = part and getSprite(part.open) or nil

    if closedSprite == nil or openSprite == nil then
        return false
    end

    if door.setOpenSprite ~= nil then
        door:setOpenSprite(openSprite)
    end
    if door.setOpen ~= nil then
        door:setOpen(false)
    end
    door:setSprite(closedSprite)

    return true
end

local function applyDurability(door, definition, craftRecipe, character)
    local maxHealth = ConstructionDurability.getEffectiveMaxHealth(
        definition,
        craftRecipe,
        character
    )

    if maxHealth ~= nil then
        DoorDurability.setEffectiveMaxHealth(door, maxHealth)
        DoorDurability.setHealth(door, maxHealth)
    end
end

function LargeGateFinalizer.finalize(square, profile, craftRecipe, character)
    if type(profile) ~= "table" or type(profile.definition) ~= "table" then
        return nil
    end

    local object, segment = BuiltLargeGatePart.find(
        square,
        profile.entityId,
        profile.leaf
    )
    if object == nil or segment == nil then
        print(string.format(
            "[LMION:DEV] LargeGate Build finalize failed: definition=%s leaf=%s entity=%s reason=no-part",
            tostring(profile.definitionId),
            tostring(profile.leaf),
            tostring(profile.entityId)
        ))
        return nil
    end

    print(string.format(
        "[LMION:DEV] LargeGate Build finalizing: definition=%s leaf=%s part=%s entity=%s facing=%s representation=%s",
        tostring(profile.definitionId),
        tostring(profile.leaf),
        tostring(segment.partIndex),
        tostring(profile.entityId),
        tostring(segment.facing),
        tostring(DoorObject.getRepresentation(object))
    ))

    local door = CanonicalDoor.ensure(object, { preserveLockState = false })
    if door == nil or not applyGeometry(door, profile, segment) then
        print(string.format(
            "[LMION:DEV] LargeGate Build finalize failed: definition=%s leaf=%s part=%s reason=canonical-or-geometry",
            tostring(profile.definitionId),
            tostring(profile.leaf),
            tostring(segment.partIndex)
        ))
        return nil
    end

    applyDurability(door, profile.definition, craftRecipe, character)

    local finalSquare = door:getSquare()
    if finalSquare ~= nil then
        finalSquare:RecalcProperties()
        finalSquare:RecalcAllWithNeighbours(true)
    end

    if isServer() and door.transmitCompleteItemToClients ~= nil then
        door:transmitCompleteItemToClients()
    end

    print(string.format(
        "[LMION:DEV] LargeGate Build finalized: definition=%s leaf=%s part=%s representation=%s health=%s max=%s",
        tostring(profile.definitionId),
        tostring(profile.leaf),
        tostring(segment.partIndex),
        tostring(DoorObject.getRepresentation(door)),
        tostring(DoorDurability.getHealth(door)),
        tostring(DoorDurability.getEffectiveMaxHealth(door))
    ))

    return door
end

return LargeGateFinalizer
