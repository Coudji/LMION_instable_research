require "BuildingObjects/ISBuildingObject"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"

local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGate/MoveProps"
local LargeGatePlacementPlan = require "LMION/Services/Moveables/LargeGate/PlacementPlan"
local SingleTileDoorMoveProps = require "LMION/Services/Moveables/SingleTileDoor/MoveProps"

LMIONDoorInventoryCursor = ISBuildingObject:derive("LMIONDoorInventoryCursor")

local function getCanonicalSpriteName(item)
    local spriteName = item and item.getWorldSprite and item:getWorldSprite() or nil
    if spriteName == nil or spriteName == "" then
        return nil
    end

    local sprite = getSprite(spriteName)
    local grid = sprite and sprite:getSpriteGrid() or nil
    if grid ~= nil then
        local anchor = grid:getSprite(0, 0)
        if anchor ~= nil then
            return anchor:getName()
        end
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
        local part = parts and parts[1] or nil
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
        1
    )
end

function LMIONDoorInventoryCursor:isValid(square)
    if square == nil or self.item == nil then
        return false
    end

    local moveProps = self:getMoveProps()
    if moveProps == nil then
        return false
    end

    return moveProps:canPlaceMoveable(self.character, square, self.item)
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

    local valid = moveProps:canPlaceMoveable(self.character, square, self.item)
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
            ISMoveablesAction:new(
                self.character,
                square,
                "place",
                self.origSpriteName,
                nil,
                self.facing,
                self.item,
                nil
            )
        )
    end
end

function LMIONDoorInventoryCursor:new(character, item, origSpriteName, kind, profile, facing, leaf)
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
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true
    return o
end

function LMIONOpenDoorInventoryPlacementCursor(item, character)
    if item == nil or character == nil then
        return false
    end

    local spriteName = getCanonicalSpriteName(item)
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil
    if moveProps == nil then
        return false
    end

    local singleProfile = SingleTileDoorMoveProps.getProfile(moveProps)
    if singleProfile ~= nil then
        local facing = SingleTileDoorMoveProps.getFacing(
            moveProps,
            singleProfile,
            spriteName
        ) or "N"

        local cursor = LMIONDoorInventoryCursor:new(
            character,
            item,
            spriteName,
            "single",
            singleProfile,
            facing,
            nil
        )
        getCell():setDrag(cursor, cursor.player)
        return true
    end

    local largeGateSegment = LargeGateMoveProps.getSegment(moveProps)
    if largeGateSegment ~= nil then
        local cursor = LMIONDoorInventoryCursor:new(
            character,
            item,
            spriteName,
            "largeGate",
            largeGateSegment.profile,
            largeGateSegment.facing,
            largeGateSegment.leaf
        )
        getCell():setDrag(cursor, cursor.player)
        return true
    end

    return false
end
