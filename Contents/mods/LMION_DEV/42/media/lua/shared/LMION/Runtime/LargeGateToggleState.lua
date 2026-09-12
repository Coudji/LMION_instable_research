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

local function findMemberOnSquare(
    square,
    logicalIndex,
    definitionId,
    facing,
    isOpen
)
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
            and segment.facing == facing
            and segment.isOpen == isOpen then
            return object
        end
    end

    return nil
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

local function collectMembers(
    anchor,
    definitionId,
    facing,
    state
)
    local isOpen = state == "open"
    local members = {}

    for logicalIndex = 1, 4 do
        local square = getSquare(anchor, facing, state, logicalIndex)
        local object = findMemberOnSquare(
            square,
            logicalIndex,
            definitionId,
            facing,
            isOpen
        )
        local segment = LargeGateMembers.getSegmentForObject(object)

        if segment == nil then
            return nil
        end

        members[logicalIndex] = {
            object = object,
            square = square,
            segment = segment,
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
    if getLogicalIndex(object) ~= 2 then
        return
    end

    local segment = LargeGateMembers.getSegmentForObject(object)
    if segment == nil then
        return
    end

    local targetOpen = object:IsOpen()

    -- During vanilla ToggleDoor(), member 2 is removed after its open-state flag
    -- has already changed, while its sprite and square still describe the previous
    -- layout. Ordinary Pickup/removal keeps both values in agreement and must not
    -- be mistaken for a toggle transition.
    if segment.isOpen == targetOpen then
        return
    end

    local previousState = segment.isOpen and "open" or "closed"
    local square = object:getSquare()
    local anchor = getAnchorFromMember(
        square,
        segment.facing,
        previousState,
        2
    )

    if anchor == nil then
        return
    end

    local members = collectMembers(
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

        local targetState = transition.targetOpen and "open" or "closed"
        local members = collectMembers(
            transition.anchor,
            transition.definitionId,
            transition.facing,
            targetState
        )

        if members ~= nil then
            local anchor = members[1] and members[1].object or nil

            if anchor ~= nil
                and restoreStates(anchor, transition.states) then
                print(string.format(
                    "[LMION:DEV] LargeGate toggle state restored: definition=%s facing=%s open=%s",
                    tostring(transition.definitionId),
                    tostring(transition.facing),
                    tostring(transition.targetOpen)
                ))
            end
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
