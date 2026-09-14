local GarageProfiles = require "LMION/Services/Moveables/Garage/Profiles"

local GarageMoveProps = {}

function GarageMoveProps.getSegment(moveProps, sprite)
    if moveProps ~= nil and moveProps.lmionGarageSegment ~= nil then
        return moveProps.lmionGarageSegment
    end

    local sourceSprite = sprite or (moveProps and moveProps.sprite)
    return GarageProfiles.getSegmentBySprite(sourceSprite)
end

function GarageMoveProps.applyProfile(moveProps, sprite)
    if moveProps == nil then
        return nil
    end

    local segment = GarageProfiles.getSegmentBySprite(sprite or moveProps.sprite)
    local profile = segment and segment.profile or nil

    if profile == nil then
        return nil
    end

    moveProps.isMoveable = true
    moveProps.customItem = segment.itemType
    moveProps.type = "Object"
    moveProps.pickUpTool = profile.pickUpTool
    moveProps.placeTool = profile.placeTool
    moveProps.pickUpLevel = profile.pickUpLevel
    moveProps.rawWeight = profile.rawWeight
    moveProps.weight = profile.weight
    moveProps.canBreak = false
    moveProps.facing = segment.facing

    moveProps.lmionGarageSegment = segment
    moveProps.lmionGarageDefinitionId = profile.definitionId
    moveProps.lmionGaragePart = segment.roleIndex
    moveProps.lmionGarageFacing = segment.facing
    moveProps.lmionGarageIsOpen = segment.isOpen

    return segment
end

function GarageMoveProps.getFaces(moveProps)
    local segment = GarageMoveProps.getSegment(moveProps)
    local profile = segment and segment.profile or nil

    if profile == nil then
        return nil
    end

    local role = segment.role
    return {
        N = profile.geometry.N[role].closed,
        W = profile.geometry.W[role].closed,
    }
end

return GarageMoveProps
