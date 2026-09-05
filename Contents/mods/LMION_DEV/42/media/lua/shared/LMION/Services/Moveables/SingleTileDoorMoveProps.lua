local DoorSprite = require "LMION/PZ/DoorSprite"
local SimpleDoorProfiles = require "LMION/Services/Moveables/SimpleDoorProfiles"

local SingleTileDoorMoveProps = {}

function SingleTileDoorMoveProps.getProfile(moveProps, sprite)
    if moveProps ~= nil and moveProps.lmionSimpleDoorProfile ~= nil then
        return moveProps.lmionSimpleDoorProfile
    end

    return SimpleDoorProfiles.getBySprite(sprite or (moveProps and moveProps.sprite or nil))
end

function SingleTileDoorMoveProps.getFacing(moveProps, profile, sprite)
    if moveProps ~= nil and moveProps.lmionSimpleDoorFacing ~= nil then
        return moveProps.lmionSimpleDoorFacing
    end

    if moveProps ~= nil and (moveProps.facing == "N" or moveProps.facing == "W") then
        return moveProps.facing
    end

    local resolvedSprite = sprite or (moveProps and moveProps.sprite or nil)
    local facing = DoorSprite.getFacing(resolvedSprite)
    if facing ~= nil then
        return facing
    end

    if type(resolvedSprite) == "string" then
        if resolvedSprite == profile.faces.N then
            return "N"
        end
        if resolvedSprite == profile.faces.W then
            return "W"
        end
    end

    return nil
end

function SingleTileDoorMoveProps.getClosedSpriteName(moveProps, profile, fallback)
    local facing = SingleTileDoorMoveProps.getFacing(moveProps, profile, fallback)
    if facing == "N" then
        return profile.faces.N
    end
    if facing == "W" then
        return profile.faces.W
    end

    return fallback
end

function SingleTileDoorMoveProps.applyProfile(moveProps, sprite)
    local profile = SimpleDoorProfiles.getBySprite(sprite)
    if moveProps == nil or profile == nil then
        return nil
    end

    local scriptItem = ScriptManager.instance:FindItem(profile.itemType)
    if scriptItem ~= nil then
        moveProps.name = scriptItem:getDisplayName()
    end

    moveProps.customItem = profile.itemType
    moveProps.type = "Object"
    moveProps.pickUpTool = profile.pickUpTool
    moveProps.placeTool = profile.placeTool
    moveProps.pickUpLevel = profile.pickUpLevel
    moveProps.rawWeight = profile.rawWeight
    moveProps.weight = profile.weight
    moveProps.canBreak = false
    moveProps.lmionSimpleDoorProfile = profile
    moveProps.lmionSimpleDoorFacing = SingleTileDoorMoveProps.getFacing(moveProps, profile, sprite)

    if moveProps.lmionSimpleDoorFacing ~= nil then
        moveProps.facing = moveProps.lmionSimpleDoorFacing
    end

    return profile
end

return SingleTileDoorMoveProps
