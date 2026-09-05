require "Moveables/ISMoveableSpriteProps"

local DoorObject = require "LMION/PZ/DoorObject"
local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local DoorSprite = require "LMION/PZ/DoorSprite"
local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"
local SimpleDoorFlatpack = require "LMION/Services/Moveables/SimpleDoorFlatpack"
local SimpleDoorPlacementFinalizer = require "LMION/Services/Moveables/SimpleDoorPlacementFinalizer"
local SimpleDoorProfiles = require "LMION/Services/Moveables/SimpleDoorProfiles"

local SimpleDoorHook = {}

local function getProfile(moveProps, sprite)
    if moveProps ~= nil and moveProps.lmionSimpleDoorProfile ~= nil then
        return moveProps.lmionSimpleDoorProfile
    end

    return SimpleDoorProfiles.getBySprite(sprite or (moveProps and moveProps.sprite or nil))
end

local function getFacing(moveProps, profile, sprite)
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

local function getClosedSpriteName(moveProps, profile, fallback)
    local facing = getFacing(moveProps, profile, fallback)
    if facing == "N" then
        return profile.faces.N
    end
    if facing == "W" then
        return profile.faces.W
    end

    return fallback
end

local function applyProfile(moveProps, sprite)
    local profile = SimpleDoorProfiles.getBySprite(sprite)
    if moveProps == nil or profile == nil then
        return nil
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
    moveProps.lmionSimpleDoorFacing = getFacing(moveProps, profile, sprite)

    if moveProps.lmionSimpleDoorFacing ~= nil then
        moveProps.facing = moveProps.lmionSimpleDoorFacing
    end

    return profile
end

local function clearPendingState(moveProps)
    moveProps.lmionPendingDoorState = nil
end

function SimpleDoorHook.install()
    if ISMoveableSpriteProps._lmionV3SimpleDoorInstalled == true then
        return false
    end

    ISMoveableSpriteProps._lmionV3SimpleDoorInstalled = true

    local originalNew = ISMoveableSpriteProps.new
    local originalHasFaces = ISMoveableSpriteProps.hasFaces
    local originalGetFaces = ISMoveableSpriteProps.getFaces
    local originalPickup = ISMoveableSpriteProps.pickUpMoveableInternal
    local originalInstanceItem = ISMoveableSpriteProps.instanceItem
    local originalCanPlace = ISMoveableSpriteProps.canPlaceMoveableInternal
    local originalPlace = ISMoveableSpriteProps.placeMoveableInternal

    ISMoveableSpriteProps.new = function(sprite)
        local moveProps = originalNew(sprite)
        applyProfile(moveProps, sprite)
        return moveProps
    end

    ISMoveableSpriteProps.hasFaces = function(self)
        local profile = getProfile(self)
        if profile ~= nil then
            return profile.faces.N ~= profile.faces.W
        end

        return originalHasFaces(self)
    end

    ISMoveableSpriteProps.getFaces = function(self)
        local profile = getProfile(self)
        if profile ~= nil then
            return {
                N = profile.faces.N,
                W = profile.faces.W,
            }
        end

        return originalGetFaces(self)
    end

    ISMoveableSpriteProps.pickUpMoveableInternal = function(self, character, square, object, sprInstance, spriteName, createItem, rotating)
        local profile = getProfile(self)
        clearPendingState(self)

        if profile ~= nil and DoorObject.isDoor(object) then
            self.lmionPendingDoorState = DoorTransportState.capture(object)
            local state = self.lmionPendingDoorState
            print(string.format(
                "[LMION:DEV] Simple pickup state captured: definition=%s health=%s max=%s",
                tostring(profile.definitionId),
                tostring(state and state.health or nil),
                tostring(state and state.maxHealth or nil)
            ))
        end

        local result = originalPickup(self, character, square, object, sprInstance, spriteName, createItem, rotating)
        clearPendingState(self)
        return result
    end

    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local profile = getProfile(self)
        local spriteName = spriteNameOverride

        if profile ~= nil then
            spriteName = getClosedSpriteName(self, profile, spriteNameOverride)
        end

        local item = originalInstanceItem(self, spriteName)

        if profile ~= nil and item ~= nil then
            local prepared = SimpleDoorFlatpack.prepare(item, profile, self.lmionPendingDoorState)
            print(string.format(
                "[LMION:DEV] Simple flatpack serialized: definition=%s item=%s prepared=%s",
                tostring(profile.definitionId),
                tostring(item:getFullType()),
                tostring(prepared)
            ))
        end

        return item
    end

    ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
        local profile = getProfile(self)
        if profile == nil then
            return originalCanPlace(self, character, square, item, forceTypeObject)
        end

        if not SimpleDoorFlatpack.matchesProfile(item, profile) then
            return false
        end

        local facing = getFacing(self, profile)
        local canPlace = DoorPlacement.canPlaceSimpleAt(square, facing)
        if not canPlace then
            return false
        end

        if character ~= nil and instanceof(character, "IsoPlayer") then
            if not ISMoveableDefinitions.cheat and not character:isMovablesCheat() then
                local hasSkill = self:hasRequiredSkill(character, "place")
                local hasTool = not self.placeTool or self:hasTool(character, "place")
                if not hasSkill or not hasTool then
                    return false
                end
            end
        end

        return true
    end

    ISMoveableSpriteProps.placeMoveableInternal = function(self, square, item, spriteName)
        local profile = getProfile(self)
        if profile == nil then
            return originalPlace(self, square, item, spriteName)
        end

        if not SimpleDoorFlatpack.matchesProfile(item, profile) then
            print(string.format(
                "[LMION:DEV] Simple placement rejected: definition=%s reason=flatpack-identity",
                tostring(profile.definitionId)
            ))
            return nil
        end

        local targetSprite = getClosedSpriteName(self, profile, spriteName)
        print(string.format(
            "[LMION:DEV] Simple placement started: definition=%s facing=%s sprite=%s",
            tostring(profile.definitionId),
            tostring(getFacing(self, profile, targetSprite)),
            tostring(targetSprite)
        ))

        local result = originalPlace(self, square, item, targetSprite)
        local finalized = SimpleDoorPlacementFinalizer.finalize(
            square,
            result,
            item,
            targetSprite,
            profile.definitionId
        )

        return finalized or result
    end

    print("[LMION:DEV] Simple Moveables hooks installed")
    return true
end

return SimpleDoorHook
