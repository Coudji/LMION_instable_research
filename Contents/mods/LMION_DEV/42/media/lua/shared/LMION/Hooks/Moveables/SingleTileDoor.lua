require "Moveables/ISMoveableSpriteProps"

local DoorObject = require "LMION/PZ/DoorObject"
local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"
local GarageMoveProps = require "LMION/Services/Moveables/Garage/MoveProps"
local LargeGateParcel = require "LMION/Runtime/Moveables/LargeGateParcel"
local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGate/MoveProps"
local SingleTileDoorMoveProps = require "LMION/Services/Moveables/SingleTileDoor/MoveProps"
local SingleTileDoorPlacement = require "LMION/Services/Common/SingleTileDoorPlacement"
local SingleTileDoorPlacementFinalizer = require "LMION/Services/Moveables/SingleTileDoor/PlacementFinalizer"

local SingleTileDoorHook = {}

local function clearPendingState(moveProps)
    moveProps.lmionPendingDoorState = nil
    moveProps.lmionPendingLargeGateSegment = nil
    moveProps.lmionPendingLargeGateState = nil
    moveProps.lmionPendingGarageSegment = nil
    moveProps.lmionPendingGarageState = nil
end

local function getLargeGateClosedSprite(segment)
    local profile = segment and segment.profile or nil
    local face = profile and profile.geometry[segment.facing] or nil
    local parts = face and face[segment.leaf] or nil
    local part = parts and parts[segment.partIndex] or nil
    return part and part.closed or nil
end

local function getGarageClosedSprite(segment)
    local profile = segment and segment.profile or nil
    local face = profile and profile.geometry[segment.facing] or nil
    local part = face and face[segment.role] or nil
    return part and part.closed or nil
end

local function getLargeGateParcelName(segment)
    local profile = segment and segment.profile or nil

    return tostring(profile and profile.displayName or segment.definitionId)
        .. " "
        .. tostring(segment.leaf)
        .. " ("
        .. tostring(segment.partIndex)
        .. "/2)"
end

local function configureLargeGateParcel(item, segment, state)
    if item == nil or segment == nil then
        return
    end

    local profile = segment.profile
    if profile ~= nil then
        item:setActualWeight(profile.weight)
        item:setWeight(profile.weight)
    end

    item:setName(getLargeGateParcelName(segment))
    item:setCustomName(true)
    LargeGateParcel.writeIdentity(item, segment)

    if state ~= nil then
        LargeGateParcel.writeState(item, state)
    end
end

local function configureGarageParcel(item, segment, state)
    if item == nil or segment == nil then
        return
    end

    local profile = segment.profile
    if profile ~= nil then
        item:setActualWeight(profile.weight)
        item:setWeight(profile.weight)
    end

    item:setName(
        tostring(
            profile
                and profile.definition
                and profile.definition.displayName
                or segment.definitionId
        ) .. " " .. tostring(segment.role)
    )
    item:setCustomName(true)

    local data = item:getModData()
    data.lmionGarageDefinitionId = segment.definitionId
    data.lmionGarageRole = segment.role

    if state ~= nil then
        DoorTransportState.writeToItem(item, state)
    end
end

local function hasPlacementRequirements(moveProps, character)
    if character == nil or not instanceof(character, "IsoPlayer") then
        return true
    end

    if ISMoveableDefinitions.cheat or character:isMovablesCheat() then
        return true
    end

    local hasSkill = moveProps:hasRequiredSkill(character, "place")
    local hasTool = not moveProps.placeTool
        or moveProps:hasTool(character, "place")

    return hasSkill and hasTool
end

function SingleTileDoorHook.install()
    if ISMoveableSpriteProps._lmionV3SingleTileDoorInstalled == true then
        return false
    end

    ISMoveableSpriteProps._lmionV3SingleTileDoorInstalled = true

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
        LargeGateMoveProps.applyProfile(moveProps, sprite)
        GarageMoveProps.applyProfile(moveProps, sprite)
        return moveProps
    end

    ISMoveableSpriteProps.hasFaces = function(self)
        local garageFaces = GarageMoveProps.getFaces(self)
        if garageFaces ~= nil then
            return garageFaces.N ~= garageFaces.W
        end

        local largeGateFaces = LargeGateMoveProps.getFaces(self)
        if largeGateFaces ~= nil then
            return largeGateFaces.N ~= largeGateFaces.W
        end

        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile ~= nil then
            return profile.faces.N ~= profile.faces.W
        end

        return originalHasFaces(self)
    end

    ISMoveableSpriteProps.getFaces = function(self)
        local garageFaces = GarageMoveProps.getFaces(self)
        if garageFaces ~= nil then
            return garageFaces
        end

        local largeGateFaces = LargeGateMoveProps.getFaces(self)
        if largeGateFaces ~= nil then
            return largeGateFaces
        end

        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile ~= nil then
            return {
                N = profile.faces.N,
                W = profile.faces.W,
            }
        end

        return originalGetFaces(self)
    end

    ISMoveableSpriteProps.pickUpMoveableInternal = function(
        self,
        character,
        square,
        object,
        sprInstance,
        spriteName,
        createItem,
        rotating
    )
        local profile = SingleTileDoorMoveProps.getProfile(self)
        local largeGateSegment = LargeGateMoveProps.getSegment(self)
        local garageSegment = GarageMoveProps.getSegment(self)

        clearPendingState(self)

        if profile ~= nil and DoorObject.isDoor(object) then
            self.lmionPendingDoorState = DoorTransportState.capture(object)
        elseif largeGateSegment ~= nil and DoorObject.isDoor(object) then
            self.lmionPendingLargeGateSegment = largeGateSegment
            self.lmionPendingLargeGateState = DoorTransportState.capture(object) or {}
        elseif garageSegment ~= nil and DoorObject.isDoor(object) then
            self.lmionPendingGarageSegment = garageSegment
            self.lmionPendingGarageState = DoorTransportState.capture(object) or {}
        end

        local result = originalPickup(
            self,
            character,
            square,
            object,
            sprInstance,
            spriteName,
            createItem,
            rotating
        )

        clearPendingState(self)
        return result
    end

    ISMoveableSpriteProps.instanceItem = function(self, spriteNameOverride)
        local profile = SingleTileDoorMoveProps.getProfile(self)
        local largeGateSegment = LargeGateMoveProps.getSegment(self)
        local garageSegment = GarageMoveProps.getSegment(self)
        local spriteName = spriteNameOverride

        if profile ~= nil then
            spriteName = SingleTileDoorMoveProps.getClosedSpriteName(
                self,
                profile,
                spriteNameOverride
            )
        elseif largeGateSegment ~= nil then
            spriteName = getLargeGateClosedSprite(largeGateSegment)
                or spriteNameOverride
        elseif garageSegment ~= nil then
            spriteName = getGarageClosedSprite(garageSegment)
                or spriteNameOverride
        end

        local item = originalInstanceItem(self, spriteName)

        if profile ~= nil
            and item ~= nil
            and self.lmionPendingDoorState ~= nil then
            DoorTransportState.writeToItem(
                item,
                self.lmionPendingDoorState
            )
        elseif largeGateSegment ~= nil and item ~= nil then
            configureLargeGateParcel(
                item,
                self.lmionPendingLargeGateSegment or largeGateSegment,
                self.lmionPendingLargeGateState
            )
        elseif garageSegment ~= nil and item ~= nil then
            configureGarageParcel(
                item,
                self.lmionPendingGarageSegment or garageSegment,
                self.lmionPendingGarageState
            )
        end

        return item
    end

    ISMoveableSpriteProps.canPlaceMoveableInternal = function(
        self,
        character,
        square,
        item,
        forceTypeObject
    )
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile == nil then
            return originalCanPlace(
                self,
                character,
                square,
                item,
                forceTypeObject
            )
        end

        local facing = SingleTileDoorMoveProps.getFacing(self, profile)
        if not SingleTileDoorPlacement.canPlace(profile, square, facing) then
            return false
        end

        return hasPlacementRequirements(self, character)
    end

    ISMoveableSpriteProps.placeMoveableInternal = function(
        self,
        square,
        item,
        spriteName
    )
        local profile = SingleTileDoorMoveProps.getProfile(self)
        if profile == nil then
            return originalPlace(self, square, item, spriteName)
        end

        local targetSprite = SingleTileDoorMoveProps.getClosedSpriteName(
            self,
            profile,
            spriteName
        )
        local result = originalPlace(self, square, item, targetSprite)
        local finalized = SingleTileDoorPlacementFinalizer.finalize(
            square,
            result,
            item,
            targetSprite,
            profile
        )

        return finalized or result
    end

    print("[LMION:DEV] door Moveables SpriteProps hooks installed")
    return true
end

return SingleTileDoorHook
