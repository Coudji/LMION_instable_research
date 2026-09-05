require "Moveables/ISMoveableSpriteProps"

local DoorObject = require "LMION/PZ/DoorObject"
local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"
local SimpleDoorPlacementFinalizer = require "LMION/Services/Moveables/SimpleDoorPlacementFinalizer"
local SingleTileDoorMoveProps = require "LMION/Services/Moveables/SingleTileDoorMoveProps"

local SimpleDoorHook = {}

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
        SingleTileDoorMoveProps.applyProfile(moveProps, sprite)
        return moveProps
    end

    ISMoveableSpriteProps.hasFaces = function(self)
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile ~= nil then
            return profile.faces.N ~= profile.faces.W
        end

        return originalHasFaces(self)
    end

    ISMoveableSpriteProps.getFaces = function(self)
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile ~= nil then
            return {
                N = profile.faces.N,
                W = profile.faces.W,
            }
        end

        return originalGetFaces(self)
    end

    ISMoveableSpriteProps.pickUpMoveableInternal = function(self, character, square, object, sprInstance, spriteName, createItem, rotating)
        local profile = SingleTileDoorMoveProps.getProfile(self)
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
        local profile = SingleTileDoorMoveProps.getProfile(self)
        local spriteName = spriteNameOverride

        if profile ~= nil then
            spriteName = SingleTileDoorMoveProps.getClosedSpriteName(self, profile, spriteNameOverride)
        end

        local item = originalInstanceItem(self, spriteName)

        if profile ~= nil and item ~= nil and self.lmionPendingDoorState ~= nil then
            DoorTransportState.writeToItem(item, self.lmionPendingDoorState)
            print(string.format(
                "[LMION:DEV] Simple transport item serialized: definition=%s item=%s",
                tostring(profile.definitionId),
                tostring(profile.itemType)
            ))
        end

        return item
    end

    ISMoveableSpriteProps.canPlaceMoveableInternal = function(self, character, square, item, forceTypeObject)
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile == nil then
            return originalCanPlace(self, character, square, item, forceTypeObject)
        end

        local facing = SingleTileDoorMoveProps.getFacing(self, profile)
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
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile == nil then
            return originalPlace(self, square, item, spriteName)
        end

        local targetSprite = SingleTileDoorMoveProps.getClosedSpriteName(self, profile, spriteName)
        print(string.format(
            "[LMION:DEV] Simple placement started: definition=%s facing=%s sprite=%s",
            tostring(profile.definitionId),
            tostring(SingleTileDoorMoveProps.getFacing(self, profile, targetSprite)),
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
