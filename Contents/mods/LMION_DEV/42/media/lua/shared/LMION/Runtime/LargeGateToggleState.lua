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

local function findLeafMemberOnSquare(
    square,
    logicalIndex,
    definitionId,
    facing,
    leaf,
    partIndex
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
            and segment.leaf == leaf
            and segment.partIndex == partIndex then
            return object
        end
    end

    return nil
end

local function collectLeafMembers(
    anchor,
    definitionId,
    facing,
    leaf,
    state
)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    if indices == nil then
        return nil
    end

    local members = {}

    for partIndex = 1, 2 do
        local logicalIndex = tonumber(indices[partIndex])
        local square = getSquare(anchor, facing, state, logicalIndex)
        local object = findLeafMemberOnSquare(
            square,
            logicalIndex,
            definitionId,
            facing,
            leaf,
            partIndex
        )

        if object == nil then
            return nil
        end

        members[partIndex] = {
            object = object,
            square = square,
            segment = LargeGateMembers.getSegmentForObject(object),
        }
    end

    return members
end

local function captureStates(members)
    if members == nil then
        return nil
    end

    local states = {}

    for partIndex = 1, 2 do
        local member = members[partIndex]
        local state = member and DoorState.capture(member.object) or nil

        if state == nil then
            return nil
        end

        states[partIndex] = state
    end

    return states
end

local function restoreStates(members, states)
    if members == nil or states == nil then
        return false
    end

    for partIndex = 1, 2 do
        local member = members[partIndex]
        local object = member and member.object or nil
        local state = states[partIndex]

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

local function makeTransitionKey(anchor, definitionId, facing, leaf)
    return table.concat({
        tostring(anchor.x),
        tostring(anchor.y),
        tostring(anchor.z),
        tostring(facing),
        tostring(definitionId),
        tostring(leaf),
    }, ":")
end

local function onAboutToRemove(object)
    local logicalIndex = getLogicalIndex(object)

    -- PZ recreates the two internal logical members of a double door: 2 and 3.
    -- Depending on facing, either one may belong to leaf A or leaf B. Treat the
    -- LMION leaf as the state-preservation unit so A/B remain fully independent.
    if logicalIndex ~= 2 and logicalIndex ~= 3 then
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
        logicalIndex
    )

    if anchor == nil then
        return
    end

    -- At this boundary IsOpen() already describes the target state while the
    -- world layout still describes the previous state. Identify only the two
    -- members of the affected leaf; the partner leaf may legitimately not exist.
    local members = collectLeafMembers(
        anchor,
        segment.definitionId,
        segment.facing,
        segment.leaf,
        previousState
    )
    local states = captureStates(members)

    if states == nil then
        return
    end

    local key = makeTransitionKey(
        anchor,
        segment.definitionId,
        segment.facing,
        segment.leaf
    )

    pendingTransitions[key] = {
        anchor = anchor,
        definitionId = segment.definitionId,
        facing = segment.facing,
        leaf = segment.leaf,
        targetOpen = targetOpen,
        states = states,
    }
end

local function onContainerUpdate()
    for key, transition in pairs(pendingTransitions) do
        pendingTransitions[key] = nil

        local targetState = transition.targetOpen and "open" or "closed"
        local members = collectLeafMembers(
            transition.anchor,
            transition.definitionId,
            transition.facing,
            transition.leaf,
            targetState
        )
        local valid = members ~= nil

        if valid then
            for partIndex = 1, 2 do
                local member = members[partIndex]
                local segment = member.segment

                if member.object:IsOpen() ~= transition.targetOpen
                    or segment == nil
                    or segment.isOpen ~= transition.targetOpen then
                    valid = false
                    break
                end
            end
        end

        if valid and restoreStates(members, transition.states) then
            print(string.format(
                "[LMION:DEV] LargeGate leaf toggle state restored: definition=%s facing=%s leaf=%s open=%s",
                tostring(transition.definitionId),
                tostring(transition.facing),
                tostring(transition.leaf),
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
