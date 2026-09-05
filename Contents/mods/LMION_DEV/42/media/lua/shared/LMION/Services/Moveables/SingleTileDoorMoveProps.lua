local DoorSprite = require "LMION/PZ/DoorSprite"
local SingleTileDoorProfiles = require "LMION/Services/Moveables/SingleTileDoorProfiles"

local SingleTileDoorMoveProps = {}

function SingleTileDoorMoveProps.getProfile(moveProps, sprite)
    if moveProps ~= nil and moveProps.lmionSingleTileDoorProfile ~= nil then
        return moveProps.lmionSingleTileDoorProfile
    end

    return SingleTileDoorProfiles.getBySprite(sprite or (moveProps and moveProps.sprite or nil))
end

function SingleTileDoorMoveProps.getFacing(moveProps, profile, sprite)
    if moveProps ~= nil and moveProps.lmionSingleTileDoorFacing ~= nil then
        return moveProps.lmionSingleTileDoorFacing
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
    local profile = SingleTileDoorProfiles.getBySprite(sprite)
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
    moveProps.lmionSingleTileDoorProfile = profile
    moveProps.lmionSingleTileDoorFacing = SingleTileDoorMoveProps.getFacing(moveProps, profile, sprite)

    if moveProps.lmionSingleTileDoorFacing ~= nil then
        moveProps.facing = moveProps.lmionSingleTileDoorFacing
    end

    return profile
end

return SingleTileDoorMoveProps
