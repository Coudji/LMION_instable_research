local CanonicalDoor = require "LMION/Runtime/CanonicalDoor"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local LargeGateParcel = require "LMION/Runtime/Moveables/LargeGateParcel"

local LargeGatePlacementFinalizer = {}

local function refreshSquare(door)
    local square = door and door:getSquare() or nil
    if square == nil then
        return
    end

    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)
end

local function restoreDurability(door, item)
    local state = LargeGateParcel.readState(item)
    if state == nil then
        return nil
    end

    if state.maxHealth ~= nil then
        DoorDurability.restoreEffectiveMaxHealth(
            door,
            state.maxHealth,
            state.maxWasLogical == true
        )
    end

    if state.health ~= nil then
        DoorDurability.setHealth(door, state.health)
    end

    return state
end

function LargeGatePlacementFinalizer.finalize(object, entry, plan, partIndex)
    if object == nil or entry == nil or plan == nil then
        return nil
    end

    local door = CanonicalDoor.ensure(object)
    if door == nil then
        return nil
    end

    local part = plan.profile.geometry[plan.facing][plan.leaf][partIndex]
    local closedSprite = part and getSprite(part.closed) or nil
    local openSprite = part and getSprite(part.open) or nil
    if part == nil or closedSprite == nil or openSprite == nil then
        return nil
    end

    if door.setOpenSprite ~= nil then
        door:setOpenSprite(openSprite)
    end
    if door.setOpen ~= nil then
        door:setOpen(plan.isOpen == true)
    end

    door:setSprite(plan.isOpen and openSprite or closedSprite)
    local state = restoreDurability(door, entry.item)
    refreshSquare(door)

    if isServer() then
        door:transmitCompleteItemToClients()
    end

    print(string.format(
        "[LMION:DEV] LargeGate member finalized: definition=%s leaf=%s part=%d facing=%s open=%s health=%s max=%s",
        tostring(plan.definitionId),
        tostring(plan.leaf),
        partIndex,
        tostring(plan.facing),
        tostring(plan.isOpen),
        tostring(state and state.health or nil),
        tostring(state and state.maxHealth or nil)
    ))

    return door
end

return LargeGatePlacementFinalizer
