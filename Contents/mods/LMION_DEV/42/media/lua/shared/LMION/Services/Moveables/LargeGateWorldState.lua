local LargeGateMembers = require "LMION/Services/Moveables/LargeGateMembers"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGateWorldState = {}

local function getSquare(anchor, offset)
    if anchor == nil or offset == nil then
        return nil
    end

    return getCell():getGridSquare(
        anchor.x + tonumber(offset[1]),
        anchor.y + tonumber(offset[2]),
        anchor.z
    )
end

local function getExpectedSprite(profile, facing, leaf, partIndex, isOpen)
    local part = profile.geometry[facing][leaf][partIndex]
    return isOpen and part.open or part.closed
end

local function findPart(profile, square, facing, leaf, partIndex, isOpen)
    if square == nil then
        return nil
    end

    local expectedSprite = getExpectedSprite(profile, facing, leaf, partIndex, isOpen)
    local specialObjects = square:getSpecialObjects()
    for index = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(index)
        local segment = LargeGateMembers.getSegmentForObject(object)
        local sprite = object and object:getSprite() or nil

        if segment ~= nil
            and segment.definitionId == profile.definitionId
            and segment.facing == facing
            and segment.leaf == leaf
            and segment.partIndex == partIndex
            and segment.isOpen == isOpen
            and sprite ~= nil
            and sprite:getName() == expectedSprite then
            return object
        end
    end

    return nil
end

local function matchesLeaf(profile, anchor, facing, leaf, state)
    local isOpen = state == "open"
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    if indices == nil then
        return false
    end

    for partIndex = 1, 2 do
        local offset = LargeGateTopology.getStateOffset(facing, state, indices[partIndex])
        local square = getSquare(anchor, offset)
        if findPart(profile, square, facing, leaf, partIndex, isOpen) == nil then
            return false
        end
    end

    return true
end

local function hasLeafFragment(profile, anchor, facing, leaf)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    if indices == nil then
        return false
    end

    for _, state in ipairs({ "closed", "open" }) do
        for partIndex = 1, 2 do
            local offset = LargeGateTopology.getStateOffset(facing, state, indices[partIndex])
            local square = getSquare(anchor, offset)
            local objects = square and square:getSpecialObjects() or nil
            if objects ~= nil then
                for objectIndex = 0, objects:size() - 1 do
                    local segment = LargeGateMembers.getSegmentForObject(objects:get(objectIndex))
                    if segment ~= nil
                        and segment.definitionId == profile.definitionId
                        and segment.facing == facing
                        and segment.leaf == leaf then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function LargeGateWorldState.getAnchor(square, facing, leaf, partIndex)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    local logicalIndex = indices and indices[partIndex] or nil
    local offset = logicalIndex and LargeGateTopology.getStateOffset(facing, "closed", logicalIndex) or nil
    if square == nil or offset == nil then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end

function LargeGateWorldState.getPartSquare(anchor, facing, leaf, partIndex, state)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    local logicalIndex = indices and indices[partIndex] or nil
    local offset = logicalIndex and LargeGateTopology.getStateOffset(facing, state, logicalIndex) or nil
    return getSquare(anchor, offset)
end

function LargeGateWorldState.getPartnerState(profile, anchor, facing, leaf)
    local partnerLeaf = LargeGateTopology.getPartnerLeaf(leaf)
    if partnerLeaf == nil then
        return "incoherent"
    end

    if matchesLeaf(profile, anchor, facing, partnerLeaf, "closed") then
        return "closed"
    end
    if matchesLeaf(profile, anchor, facing, partnerLeaf, "open") then
        return "open"
    end
    if hasLeafFragment(profile, anchor, facing, partnerLeaf) then
        return "incoherent"
    end

    return "none"
end

return LargeGateWorldState
