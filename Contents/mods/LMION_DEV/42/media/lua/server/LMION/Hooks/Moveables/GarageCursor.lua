require "BuildingObjects/ISBuildingObject"
require "Moveables/ISMoveablesAction"

local GaragePlacement = require "LMION/Services/Moveables/GaragePlacement"
local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"

local function getPlacementMoveProps(definitionId, facing)
    local profile = GarageProfiles.getByDefinitionId(definitionId)
    local face = profile and profile.geometry and profile.geometry[facing] or nil
    local start = face and face.START or nil
    local spriteName = start and start.closed or nil
    local moveProps = spriteName and ISMoveableSpriteProps.new(spriteName) or nil

    if moveProps ~= nil then
        -- The dedicated variable-width cursor owns the complete Garage plan.
        -- ISMoveablesAction only needs one physical member here for its normal
        -- tool/sound/duration context, never the synthetic L3 SpriteGrid.
        moveProps.isMultiSprite = false
    end

    return moveProps
end

LMIONGaragePlacementAction = ISMoveablesAction:derive("LMIONGaragePlacementAction")

function LMIONGaragePlacementAction:isValid()
    local playerSquare = self.character and self.character:getSquare() or nil
    if playerSquare == nil
        or self.square == nil
        or playerSquare:getZ() ~= self.square:getZ() then
        return false
    end

    local plan = GaragePlacement.buildPlan(
        self.character,
        self.definitionId,
        self.length,
        self.facing,
        self.square
    )
    if plan == nil or not GaragePlacement.validate(self.character, plan) then
        return false
    end

    if not ISMoveableDefinitions.cheat and not self.character:isMovablesCheat() then
        local adjacent = false
        for position = 1, plan.length do
            local targetSquare = plan[position].square
            if targetSquare == playerSquare or playerSquare:isAdjacentTo(targetSquare) then
                adjacent = true
                break
            end
        end

        if not adjacent then
            return false
        end
    end

    if isClient()
        and SafeHouse.isSafeHouse(self.square, self.character:getUsername(), true)
        and not SafeHouse.isSafehouseAllowLoot(self.square, self.character) then
        return false
    end

    return true
end

function LMIONGaragePlacementAction:complete()
    local plan = GaragePlacement.buildPlan(
        self.character,
        self.definitionId,
        self.length,
        self.facing,
        self.square
    )
    if plan == nil then
        return false
    end

    local placed = GaragePlacement.place(self.character, plan)
    if placed == nil then
        return false
    end

    if buildUtil ~= nil and buildUtil.setHaveConstruction ~= nil then
        for position = 1, plan.length do
            buildUtil.setHaveConstruction(plan[position].square, true)
        end
    end

    return true
end

function LMIONGaragePlacementAction:new(character, square, definitionId, length, facing)
    local o = ISBaseTimedAction.new(self, character)
    o.playerNum = character:getPlayerNum()
    o.square = square
    o.definitionId = definitionId
    o.length = length
    o.facing = facing
    o.mode = "place"

    -- ISMoveablesAction.start()/setActionSound() expects the normal Moveables
    -- context to exist even though LMION owns the actual multi-member placement.
    -- Legacy supplied these fields too; omitting them caused getSoundFromTool to
    -- be indexed through a nil moveProps after an otherwise-successful placement.
    o.moveProps = getPlacementMoveProps(definitionId, facing)
    o.origMoveProps = o.moveProps
    o.origSpriteName = o.moveProps and o.moveProps.spriteName or nil

    o.maxTime = o:getDuration()
    return o
end

LMIONGaragePlacementCursor = ISBuildingObject:derive("LMIONGaragePlacementCursor")

local function widthKey(optionId, fallback)
    if PZAPI ~= nil and PZAPI.ModOptions ~= nil then
        local options = PZAPI.ModOptions:getOptions("LMION_GaragePlacement")
        local option = options and options:getOption(optionId) or nil
        if option ~= nil then
            return option:getValue()
        end
    end

    return fallback
end

function LMIONGaragePlacementCursor:getPlan(square)
    return GaragePlacement.buildPlan(
        self.character,
        self.definitionId,
        self.selectedLength,
        self.facing,
        square
    )
end

function LMIONGaragePlacementCursor:getMaximumLength()
    return GaragePlacement.getMaximumAvailableLength(
        self.character,
        self.definitionId
    )
end

function LMIONGaragePlacementCursor:isValid(square)
    local maximum = self:getMaximumLength()
    if maximum == nil then
        return false
    end

    self.selectedLength = math.max(2, math.min(self.selectedLength, maximum))
    local plan = self:getPlan(square)
    return plan ~= nil and GaragePlacement.validate(self.character, plan)
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

function LMIONGaragePlacementCursor:render(x, y, z, square)
    local plan = self:getPlan(square)
    if plan == nil then
        return
    end

    local valid = GaragePlacement.validate(self.character, plan)
    local r = valid and 0.5 or 1.0
    local g = valid and 1.0 or 0.0
    local b = valid and 0.5 or 0.0

    for position = 1, plan.length do
        local entry = plan[position]
        floorGhost(entry.square)

        local sprite = getSprite(entry.spriteName)
        if sprite ~= nil then
            sprite:RenderGhostTileColor(
                entry.square:getX(),
                entry.square:getY(),
                entry.square:getZ(),
                0,
                0,
                r,
                g,
                b,
                0.8
            )
        end
    end
end

function LMIONGaragePlacementCursor:rotateMouse(x, y)
end

function LMIONGaragePlacementCursor:rotateKey(key)
    local decreaseKey = widthKey("GarageWidthDecrease", Keyboard.KEY_SUBTRACT)
    local increaseKey = widthKey("GarageWidthIncrease", Keyboard.KEY_ADD)

    if key == decreaseKey then
        local previous = self.selectedLength
        self.selectedLength = math.max(2, self.selectedLength - 1)
        if previous ~= self.selectedLength then
            getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
        end
        return
    end

    if key == increaseKey then
        local maximum = self:getMaximumLength()
        if maximum ~= nil then
            local previous = self.selectedLength
            self.selectedLength = math.min(maximum, self.selectedLength + 1)
            if previous ~= self.selectedLength then
                getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
            end
        end
        return
    end

    if getCore():isKey("Rotate building", key) then
        self.facing = self.facing == "N" and "W" or "N"
        getSoundManager():playUISound("UIObjectMenuObjectRotateOutline")
    end
end

function LMIONGaragePlacementCursor:create(x, y, z, north, sprite)
    local square = getCell():getGridSquare(x, y, z)
    local plan = self:getPlan(square)
    if plan == nil or not GaragePlacement.validate(self.character, plan) then
        return
    end

    local moveProps = getPlacementMoveProps(self.definitionId, self.facing)
    if moveProps == nil then
        return
    end

    if ISMoveableDefinitions.cheat
        or moveProps:walkToAndEquip(
            self.character,
            square,
            "place",
            plan[1].spriteName
        ) then
        ISTimedActionQueue.add(
            LMIONGaragePlacementAction:new(
                self.character,
                square,
                self.definitionId,
                self.selectedLength,
                self.facing
            )
        )
    end
end

function LMIONGaragePlacementCursor:new(character, definitionId, facing)
    local o = ISBuildingObject.new(self)
    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.definitionId = definitionId
    o.facing = facing == "W" and "W" or "N"
    o.selectedLength = GaragePlacement.getMaximumAvailableLength(
        character,
        definitionId
    ) or 2
    o:setDragNilAfterPlace(true)
    o.noNeedHammer = true
    return o
end

function LMIONOpenGaragePlacementCursor(item, character)
    if item == nil or character == nil then
        return false
    end

    local data = item:getModData()
    local definitionId = data and data.lmionGarageDefinitionId or nil
    if GarageProfiles.getByDefinitionId(definitionId) == nil then
        return false
    end

    local facing = "N"
    local worldSprite = item.getWorldSprite and item:getWorldSprite() or nil
    local segment = worldSprite and GarageProfiles.getSegmentBySprite(worldSprite) or nil
    if segment ~= nil then
        facing = segment.facing
    end

    if GaragePlacement.getMaximumAvailableLength(character, definitionId) == nil then
        return false
    end

    local cursor = LMIONGaragePlacementCursor:new(
        character,
        definitionId,
        facing
    )
    getCell():setDrag(cursor, cursor.player)
    return true
end
