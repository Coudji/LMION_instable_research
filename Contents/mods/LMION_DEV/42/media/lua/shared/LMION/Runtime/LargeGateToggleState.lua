local DoorState = require "LMION/Runtime/DoorState"
local LargeGateMembers = require "LMION/Services/Moveables/LargeGateMembers"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGateToggleState = {}

local pendingTransitions = {}
local installed = false

local function getLogicalIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorIndex, object)
    value = ok and tonumber(value) or nil

    if value == nil or value < 1 or value > 4 then
        return nil
    end

    return value
end

local function getDoubleDoorObject(source, logicalIndex)
    if source == nil or IsoDoor == nil or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local ok, object = pcall(IsoDoor.getDoubleDoorObject, source, logicalIndex)
    return ok and object or nil
end

local function getGateMembers(source)
    local sourceSegment = LargeGateMembers.getSegmentForObject(source)
    if sourceSegment == nil then
        return nil
    end

    local members = {}

    for logicalIndex = 1, 4 do
        local object = getDoubleDoorObject(source, logicalIndex)
        local segment = LargeGateMembers.getSegmentForObject(object)

        if segment == nil
            or segment.definitionId ~= sourceSegment.definitionId
            or segment.facing ~= sourceSegment.facing
            or segment.isOpen ~= sourceSegment.isOpen then
            return nil
        end

        members[logicalIndex] = {
            object = object,
            square = object:getSquare(),
            segment = segment,
        }
    end

    return members
end

local function captureStates(members)
    if members == nil then
        return nil
    end

    local states = {}

    for logicalIndex = 1, 4 do
        local member = members[logicalIndex]
        local state = member and DoorState.capture(member.object) or nil

        if state == nil then
            return nil
        end

        states[logicalIndex] = state
    end

    return states
end

local function restoreStates(source, states)
    if source == nil or states == nil then
        return false
    end

    for logicalIndex = 1, 4 do
        local object = getDoubleDoorObject(source, logicalIndex)
        local state = states[logicalIndex]

        if not DoorState.restore(object, state) then
            return false
        end

        if isServer ~= nil
            and isServer()
            and object.transmitCompleteItemToClients ~= nil then
            object:transmitCompleteItemToClients()
        end
    end

    return true
end

local function getSquare(anchor, facing, state, logicalIndex)
    local offset = LargeGateTopology.getStateOffset(facing, state, logicalIndex)
    if anchor == nil or offset == nil then
        return nil
    end

    return getCell():getGridSquare(
        anchor.x + tonumber(offset[1]),
        anchor.y + tonumber(offset[2]),
        anchor.z
    )
end

local function getAnchorFromMember(square, facing, state, logicalIndex)
    local offset = LargeGateTopology.getStateOffset(facing, state, logicalIndex)
    if square == nil or offset == nil then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end

local function findKnownOnSquare(square, logicalIndex, definitionId, facing)
    if square == nil then
        return nil
    end

    local objects = square:getSpecialObjects()

    for objectIndex = 0, objects:size() - 1 do
        local object = objects:get(objectIndex)
        local segment = LargeGateMembers.getSegmentForObject(object)

        if segment ~= nil
            and getLogicalIndex(object) == logicalIndex
            and segment.definitionId == definitionId
            and segment.facing == facing then
            return object
        end
    end

    return nil
end

local function collectKnownMembers(anchor, definitionId, facing, state)
    local members = {}

    for logicalIndex = 1, 4 do
        local square = getSquare(anchor, facing, state, logicalIndex)
        local object = findKnownOnSquare(
            square,
            logicalIndex,
            definitionId,
            facing
        )

        if object == nil then
            return nil
        end

        members[logicalIndex] = {
            object = object,
            square = square,
            segment = LargeGateMembers.getSegmentForObject(object),
        }
    end

    return members
end

local function makeTransitionKey(anchor, definitionId, facing)
    return table.concat({
        tostring(anchor.x),
        tostring(anchor.y),
        tostring(anchor.z),
        tostring(facing),
        tostring(definitionId),
    }, ":")
end

local function onAboutToRemove(object)
    -- Vanilla recreates LargeGate members during ToggleDoor(). Member 2 is the
    -- stable point where Legacy observed the transition: IsOpen() already holds
    -- the target state while sprite/square still describe the previous layout.
    if getLogicalIndex(object) ~= 2 then
        return
    end

    local segment = LargeGateMembers.getSegmentForObject(object)
    if segment == nil then
        return
    end

    local targetOpen = object:IsOpen()
    local previousState = targetOpen and "closed" or "open"
    local anchor = getAnchorFromMember(
        object:getSquare(),
        segment.facing,
        previousState,
        2
    )

    if anchor == nil then
        return
    end

    -- Deliberately identify the old members from their previous-layout squares,
    -- logical indices and profile identity only. Do not require sprite open-state
    -- parity here: during ToggleDoor() the engine is between both representations.
    -- Ordinary Pickup/removal does not form the opposite layout, so it naturally
    -- fails this collection instead of needing a separate removal heuristic.
    local members = collectKnownMembers(
        anchor,
        segment.definitionId,
        segment.facing,
        previousState
    )
    local states = captureStates(members)

    if states == nil then
        return
    end

    local key = makeTransitionKey(
        anchor,
        segment.definitionId,
        segment.facing
    )

    pendingTransitions[key] = {
        anchor = anchor,
        definitionId = segment.definitionId,
        facing = segment.facing,
        targetOpen = targetOpen,
        states = states,
    }
end

local function onContainerUpdate()
    for key, transition in pairs(pendingTransitions) do
        pendingTransitions[key] = nil

        local anchorSquare = getCell():getGridSquare(
            transition.anchor.x,
            transition.anchor.y,
            transition.anchor.z
        )
        local anchor = findKnownOnSquare(
            anchorSquare,
            1,
            transition.definitionId,
            transition.facing
        )
        local members = anchor and getGateMembers(anchor) or nil
        local valid = members ~= nil

        if valid then
            for logicalIndex = 1, 4 do
                if members[logicalIndex].object:IsOpen() ~= transition.targetOpen then
                    valid = false
                    break
                end
            end
        end

        if valid and restoreStates(anchor, transition.states) then
            print(string.format(
                "[LMION:DEV] LargeGate toggle state restored: definition=%s facing=%s open=%s",
                tostring(transition.definitionId),
                tostring(transition.facing),
                tostring(transition.targetOpen)
            ))
        end
    end
end

function LargeGateToggleState.install()
    if installed then
        return false
    end

    if Events == nil
        or Events.OnObjectAboutToBeRemoved == nil
        or Events.OnContainerUpdate == nil then
        return false
    end

    installed = true
    Events.OnObjectAboutToBeRemoved.Add(onAboutToRemove)
    Events.OnContainerUpdate.Add(onContainerUpdate)

    print("[LMION:DEV] LargeGate toggle state preservation installed")
    return true
end

return LargeGateToggleState
