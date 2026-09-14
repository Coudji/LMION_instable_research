require "BuildingObjects/ISBuildingObject"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LargeGateParcel = require "LMION/Runtime/Moveables/LargeGateParcel"
local LargeGatePlacementPlan = require "LMION/Services/Moveables/LargeGate/PlacementPlan"
local LargeGateProfiles = require "LMION/Services/Moveables/LargeGate/Profiles"
local SingleTileDoorMoveProps = require "LMION/Services/Moveables/SingleTileDoor/MoveProps"

LMIONDoorInventoryPlacementAction = ISMoveablesAction:derive(
    "LMIONDoorInventoryPlacementAction"
)
LMIONDoorInventoryCursor = ISBuildingObject:derive("LMIONDoorInventoryCursor")

local function getItemSpriteName(item)
    local spriteName = item and item.getWorldSprite and item:getWorldSprite() or nil
    if type(spriteName) ~= "string" or spriteName == "" then
        return nil
    end
    return spriteName
end

local function floorGhost(square)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil
    if sprite ~= nil then
        sprite:RenderGhostTileColor(
            square:getX(),
            square:getY(),
            square:getZ(),
            0.75,
            1,
            0.75,
            0.25
        )
    end
end

local function renderSprite(spriteName, square, yOffset, valid)
    local sprite = spriteName and getSprite(spriteName) or nil
    if sprite == nil or square == nil then
        return
    end

    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        (yOffset or 0) * Core.getTileScale(),
        r,
        g,
        b,
        0.8
    )
end

function LMIONDoorInventoryPlacementAction:new(
    character,
    square,
    moveProps,
    origSpriteName,
    item
)
    local o = ISBaseTimedAction.new(self, character)
    o.playerNum = character:getPlayerNum()
    o.square = square
    o.mode = "place"
    o.moveProps = moveProps
    o.origMoveProps = moveProps
    o.origSpriteName = origSpriteName
    o.item = item
    o.maxTime = o:getDuration()
    return o
end

function LMIONDoorInventoryCursor:getMoveProps()
    local spriteName = nil

    if self.kind == "single" then
        spriteName = self.profile
            and self.profile.faces
            and self.profile.faces[self.facing]
            or nil
    elseif self.kind == "largeGate" then
        local parts = self.profile
            and self.profile.geometry
            and self.profile.geometry[self.facing]
            and self.profile.geometry[self.facing][self.leaf]
            or nil
        local part = parts and parts[self.selectedPart] or nil
        spriteName = part and part.closed or nil
    end

    if spriteName == nil then
        return nil
    end

    return ISMoveableSpriteProps.new(spriteName)
end

function LMIONDoorInventoryCursor:getLargeGatePlan(square)
    if self.kind ~= "largeGate" then
        return nil
    end

    return LargeGatePlacementPlan.build(
        self.character,
        square,
        self.profile.definitionId,
        self.facing,
        self.leaf,
        self.selectedPart
    )
end

function LMIONDoorInventoryCursor:isValid(square)
    if square == nil or self.item == nil then
        return false
    end

    if self.kind == "largeGate" then
        local plan = self:getLargeGatePlan(square)
        return plan ~= nil and plan.valid == true
    end

    local moveProps = self:getMoveProps()
    return moveProps ~= nil
        and moveProps:canPlaceMoveable(self.character, square, self.item)
end

function LMIONDoorInventoryCursor:render(x, y, z, square)
    square = square or getCell():getGridSquare(x, y, z)
    if square == nil then
        return
    end

    if self.kind == "largeGate" then
        local plan = self:getLargeGatePlan(square)
        if plan == nil then
            return
        end

        local valid = plan.valid == true
        for partIndex = 1, 2 do
            local entry = plan[partIndex]
            if entry ~= nil then
                floorGhost(entry.square)
                renderSprite(entry.displaySprite, entry.square, 0, valid)
            end
        end
        return
    end

    local moveProps = self:getMoveProps()
    if moveProps == nil then
        return
    end

    local valid = moveProps:canPlaceMoveable(
        self.character,
        square,
        self.item
    )
    floorGhost(square)
    renderSprite(
        moveProps.spriteName,
        square,
        moveProps:getYOffsetCursor(),
        valid
    )
end

function LMIONDoorInventoryCursor:rotateMouse(x, y)
end

function LMIONDoorInventoryCursor:rotateKey(key)
    if not getCore():isKey("Rotate building", key) then
        return
    end

    self.facing = self.facing == "N" and "W" or "N"
    getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
end

function LMIONDoorInventoryCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)
    if square == nil or not self:isValid(square) then
        return
    end

    local moveProps = self:getMoveProps()
    if moveProps == nil then
        return
    end

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(
            self.character,
            square,
            "place",
            self.origSpriteName
        ) then
        ISTimedActionQueue.add(
            LMIONDoorInventoryPlacementAction:new(
                self.character,
                square,
                moveProps,
                self.origSpriteName,
                self.item
            )
        )
    end
end

function LMIONDoorInventoryCursor:new(
    character,
    item,
    origSpriteName,
    kind,
    profile,
    facing,
    leaf,
    selectedPart
)
    local o = ISBuildingObject.new(self)
    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.item = item
    o.origSpriteName = origSpriteName
    o.kind = kind
    o.profile = profile
    o.facing = facing == "W" and "W" or "N"
    o.leaf = leaf
    o.selectedPart = selectedPart
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true
    return o
end

local function openLargeGateCursor(item, character, spriteName)
    local identity = LargeGateParcel.readIdentity(item)
    if identity == nil then
        return false
    end

    local profile = LargeGateProfiles.getByDefinitionId(identity.definitionId)
    if profile == nil then
        return false
    end

    local segment = LargeGateProfiles.getSegmentBySprite(spriteName)
    local facing = segment and segment.facing or "N"

    local cursor = LMIONDoorInventoryCursor:new(
        character,
        item,
        spriteName,
        "largeGate",
        profile,
        facing,
        identity.leaf,
        identity.partIndex
    )
    getCell():setDrag(cursor, cursor.player)
    return true
end

local function openSingleTileCursor(item, character, spriteName)
    local moveProps = ISMoveableSpriteProps.new(spriteName)
    if moveProps == nil then
        return false
    end

    local profile = SingleTileDoorMoveProps.getProfile(moveProps)
    if profile == nil then
        return false
    end

    local facing = SingleTileDoorMoveProps.getFacing(
        moveProps,
        profile,
        spriteName
    ) or "N"

    local cursor = LMIONDoorInventoryCursor:new(
        character,
        item,
        spriteName,
        "single",
        profile,
        facing,
        nil,
        nil
    )
    getCell():setDrag(cursor, cursor.player)
    return true
end

function LMIONOpenDoorInventoryPlacementCursor(item, character)
    if item == nil or character == nil then
        return false
    end

    local spriteName = getItemSpriteName(item)
    if spriteName == nil then
        return false
    end

    if openLargeGateCursor(item, character, spriteName) then
        return true
    end

    return openSingleTileCursor(item, character, spriteName)
end
