require "BuildingObjects/ISMoveableCursor"

local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"
local LargeGateGhostParts = require "LMION/Services/Moveables/LargeGateGhostParts"

local function getSegment(moveProps)
    local sprite = moveProps and moveProps.sprite or nil
    return LargeGateProfiles.getSegmentBySprite(sprite)
end

local function getGridOrigin(self, x, y)
    local origSprite = self.origMoveProps and self.origMoveProps.sprite or nil
    local origGrid = origSprite and origSprite:getSpriteGrid() or nil
    if origGrid == nil then
        return nil, nil
    end

    return x - origGrid:getSpriteGridPosX(origSprite),
        y - origGrid:getSpriteGridPosY(origSprite)
end

local function getPartSquares(segment, worldX, worldY, z)
    if segment == nil then
        return nil
    end

    local squares = {}
    for partIndex = 1, 2 do
        local x = worldX
        local y = worldY
        if segment.facing == "N" then
            x = x + partIndex - 1
        elseif segment.facing == "W" then
            y = y + partIndex - 1
        else
            return nil
        end

        squares[partIndex] = getCell():getGridSquare(x, y, z)
    end

    return squares
end

local function renderFloor(square)
    local floor = square and square:getFloor() or nil
    local sprite = floor and floor:getSprite() or nil
    if sprite == nil then
        return
    end

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

local function renderPart(sprite, square, self, color)
    if sprite == nil or square == nil then
        return
    end

    sprite:RenderGhostTileColor(
        square:getX(),
        square:getY(),
        square:getZ(),
        0,
        self.yOffset * Core.getTileScale(),
        color.r,
        color.g,
        color.b,
        0.8
    )
end

local function renderLargeGateGrid(self, x, y, z, color, segment)
    local profile = segment.profile
    local currentSprite = self.currentMoveProps and self.currentMoveProps.sprite or nil
    local spriteGrid = currentSprite and currentSprite:getSpriteGrid() or nil
    local worldX, worldY = getGridOrigin(self, x, y)
    if profile == nil or spriteGrid == nil or worldX == nil then
        return false
    end

    local squares = getPartSquares(segment, worldX, worldY, z)
    if squares == nil then
        return false
    end

    for partIndex = 1, 2 do
        renderFloor(squares[partIndex])
    end

    for partIndex = 1, 2 do
        if LargeGateGhostParts.shouldRender(
            profile,
            segment.facing,
            segment.leaf,
            partIndex,
            squares
        ) then
            local part = profile.geometry[segment.facing][segment.leaf][partIndex]
            renderPart(getSprite(part.closed), squares[partIndex], self, color)
        end
    end

    return true
end

if ISMoveableCursor._lmionV3LargeGateGridGhostInstalled ~= true then
    ISMoveableCursor._lmionV3LargeGateGridGhostInstalled = true

    local previousRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid

    ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
        local originalSegment = getSegment(self.origMoveProps)
        local currentSegment = getSegment(self.currentMoveProps)

        if originalSegment == nil
            or currentSegment == nil
            or originalSegment.isOpen
            or currentSegment.isOpen then
            return previousRenderSpriteGrid(self, x, y, z, color)
        end

        if renderLargeGateGrid(self, x, y, z, color, currentSegment) then
            return
        end

        return previousRenderSpriteGrid(self, x, y, z, color)
    end

    print("[LMION:DEV] LargeGate SpriteGrid ghost hook installed")
end
