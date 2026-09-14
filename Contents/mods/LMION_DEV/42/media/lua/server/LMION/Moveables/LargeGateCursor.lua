require "BuildingObjects/ISMoveableCursor"

local GarageMembers = require "LMION/Services/Moveables/GarageMembers"
local GarageMoveProps = require "LMION/Services/Moveables/GarageMoveProps"
local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"
local LargeGateGhostParts = require "LMION/Services/Moveables/LargeGateGhostParts"

local function getLargeGateSegment(moveProps)
    local sprite = moveProps and moveProps.sprite or nil
    return LargeGateProfiles.getSegmentBySprite(sprite)
end

local function getGarageSegment(moveProps)
    return GarageMoveProps.getSegment(moveProps)
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

local function renderFloorFootprint(members)
    for index = 1, #members do
        renderFloor(members[index].square)
    end
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

local function getGarageMembersForCursor(self, x, y, z)
    local moveProps = self.currentMoveProps
    local segment = getGarageSegment(moveProps)
    if segment == nil then
        return nil
    end

    local square = self.currentSquare or getCell():getGridSquare(x, y, z)
    local selected = square and moveProps:findOnSquare(square, moveProps.spriteName) or nil
    if selected == nil then
        return nil
    end

    return GarageMembers.getMembers(selected, segment.definitionId)
end

if ISMoveableCursor._lmionV3MultipartGhostInstalled ~= true then
    ISMoveableCursor._lmionV3MultipartGhostInstalled = true

    local previousRender = ISMoveableCursor.render
    local previousRenderSpriteGrid = ISMoveableCursor.renderSpriteGrid

    ISMoveableCursor.render = function(self, x, y, z, square)
        local result = previousRender(self, x, y, z, square)
        local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
        if mode ~= "pickup" then
            return result
        end

        local segment = getGarageSegment(self.currentMoveProps)
        if segment == nil or segment.isOpen ~= true then
            return result
        end

        local members = getGarageMembersForCursor(self, x, y, z)
        if members ~= nil then
            renderFloorFootprint(members)
        end

        return result
    end

    ISMoveableCursor.renderSpriteGrid = function(self, x, y, z, color)
        local mode = ISMoveableCursor.mode and ISMoveableCursor.mode[self.player] or nil
        if mode == "pickup" then
            local originalGarageSegment = getGarageSegment(self.origMoveProps)
            local currentGarageSegment = getGarageSegment(self.currentMoveProps)

            if originalGarageSegment ~= nil and currentGarageSegment ~= nil then
                local members = getGarageMembersForCursor(self, x, y, z)
                if members ~= nil then
                    -- Garage SpriteGrid is intentionally fixed L3 only as a vanilla
                    -- Moveables discovery/rotation adapter. Pickup must display the
                    -- actual native START/MIDDLE*/END chain, whatever its length.
                    renderFloorFootprint(members)
                    return
                end
            end
        end

        local originalSegment = getLargeGateSegment(self.origMoveProps)
        local currentSegment = getLargeGateSegment(self.currentMoveProps)

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

    print("[LMION:DEV] multipart Moveables ghost hook installed")
end
