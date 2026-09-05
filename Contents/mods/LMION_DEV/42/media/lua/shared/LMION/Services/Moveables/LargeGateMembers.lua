local DoorObject = require "LMION/PZ/DoorObject"
local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGateMembers = {}

local function getLogicalIndex(object)
    if object == nil or IsoDoor == nil or IsoDoor.getDoubleDoorIndex == nil then
        return nil
    end

    local ok, value = pcall(IsoDoor.getDoubleDoorIndex, object)
    return ok and tonumber(value) or nil
end

function LargeGateMembers.getSegmentForObject(object)
    if not DoorObject.isDoor(object) then
        return nil
    end

    local sprite = object:getSprite()
    local segment = LargeGateProfiles.getSegmentBySprite(sprite)
    if segment == nil then
        return nil
    end

    return getLogicalIndex(object) == tonumber(segment.logicalIndex) and segment or nil
end

function LargeGateMembers.getLeaf(source, sourceSegment)
    if source == nil
        or sourceSegment == nil
        or IsoDoor == nil
        or IsoDoor.getDoubleDoorObject == nil then
        return nil
    end

    local indices = LargeGateTopology.getLeafIndices(sourceSegment.facing, sourceSegment.leaf)
    if indices == nil then
        return nil
    end

    local members = {}
    for partIndex = 1, 2 do
        local ok, object = pcall(IsoDoor.getDoubleDoorObject, source, tonumber(indices[partIndex]))
        if not ok or object == nil then
            return nil
        end

        local segment = LargeGateMembers.getSegmentForObject(object)
        if segment == nil
            or segment.definitionId ~= sourceSegment.definitionId
            or segment.facing ~= sourceSegment.facing
            or segment.leaf ~= sourceSegment.leaf
            or segment.partIndex ~= partIndex
            or segment.isOpen ~= sourceSegment.isOpen then
            return nil
        end

        members[partIndex] = {
            object = object,
            square = object:getSquare(),
            segment = segment,
        }
    end

    return members
end

return LargeGateMembers
