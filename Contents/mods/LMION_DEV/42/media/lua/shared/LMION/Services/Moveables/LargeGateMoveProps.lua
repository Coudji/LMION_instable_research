local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"

local LargeGateMoveProps = {}

local function getSpriteName(sprite)
    if sprite == nil then
        return nil
    end
    if type(sprite) == "string" then
        return sprite
    end
    return sprite:getName()
end

function LargeGateMoveProps.getSegment(moveProps, sprite)
    if moveProps ~= nil and moveProps.lmionLargeGateSegment ~= nil then
        return moveProps.lmionLargeGateSegment
    end

    return LargeGateProfiles.getSegmentBySprite(sprite or (moveProps and moveProps.sprite or nil))
end

function LargeGateMoveProps.getProfile(moveProps, sprite)
    local segment = LargeGateMoveProps.getSegment(moveProps, sprite)
    return segment and segment.profile or nil
end

function LargeGateMoveProps.getFaces(moveProps)
    local segment = LargeGateMoveProps.getSegment(moveProps)
    local profile = segment and segment.profile or nil
    if profile == nil then
        return nil
    end

    local northParts = profile.geometry.N[segment.leaf]
    local westParts = profile.geometry.W[segment.leaf]
    local north = northParts and northParts[segment.partIndex] or nil
    local west = westParts and westParts[segment.partIndex] or nil
    if north == nil or west == nil then
        return nil
    end

    return {
        N = north.closed,
        W = west.closed,
    }
end

function LargeGateMoveProps.applyProfile(moveProps, sprite)
    if moveProps == nil then
        return nil
    end

    local segment = LargeGateProfiles.getSegmentBySprite(sprite or moveProps.sprite)
    local profile = segment and segment.profile or nil
    if profile == nil then
        return nil
    end

    moveProps.isMoveable = true
    moveProps.customItem = profile.itemType
    moveProps.type = "Object"
    moveProps.pickUpTool = profile.pickUpTool
    moveProps.placeTool = profile.placeTool
    moveProps.pickUpLevel = profile.pickUpLevel
    moveProps.rawWeight = profile.rawWeight
    moveProps.weight = profile.weight
    moveProps.canBreak = false
    moveProps.facing = segment.facing

    moveProps.lmionLargeGateSegment = segment
    moveProps.lmionLargeGateDefinitionId = profile.definitionId
    moveProps.lmionLargeGateFacing = segment.facing
    moveProps.lmionLargeGateLeaf = segment.leaf
    moveProps.lmionLargeGatePart = segment.partIndex
    moveProps.lmionLargeGateIsOpen = segment.isOpen
    moveProps.lmionLargeGateSpriteName = getSpriteName(sprite or moveProps.sprite)

    return segment
end

return LargeGateMoveProps
