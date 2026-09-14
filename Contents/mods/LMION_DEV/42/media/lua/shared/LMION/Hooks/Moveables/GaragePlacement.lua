require "Moveables/ISMoveableSpriteProps"

local GarageMoveProps = require "LMION/Services/Moveables/Garage/MoveProps"
local GarageParcelLookup = require "LMION/Services/Moveables/Garage/ParcelLookup"
local GaragePlacement = require "LMION/Services/Moveables/Garage/Placement"

local GaragePlacementHook = {}

local OPPOSITE_ROLE = {
    START = "END",
    MIDDLE = "MIDDLE",
    END = "START",
}

local function getRotationFaces(segment)
    local profile = segment and segment.profile or nil
    if profile == nil then
        return nil
    end

    local oppositeRole = OPPOSITE_ROLE[segment.role]

    if segment.facing == "N" then
        return {
            N = profile.geometry.N[segment.role].closed,
            W = profile.geometry.W[oppositeRole].closed,
        }
    end

    return {
        N = profile.geometry.N[oppositeRole].closed,
        W = profile.geometry.W[segment.role].closed,
    }
end

local function getStartSquare(segment, square)
    if segment == nil or square == nil then
        return nil
    end

    local offset = (segment.roleIndex or 1) - 1

    if segment.facing == "N" then
        return getCell():getGridSquare(
            square:getX() - offset,
            square:getY(),
            square:getZ()
        )
    end

    return getCell():getGridSquare(
        square:getX(),
        square:getY() + offset,
        square:getZ()
    )
end

local function buildFixedLengthPlan(moveProps, character, square)
    local segment = GarageMoveProps.getSegment(moveProps)
    if segment == nil then
        return nil
    end

    return GaragePlacement.buildPlan(
        character,
        segment.definitionId,
        3,
        segment.facing,
        getStartSquare(segment, square)
    )
end

function GaragePlacementHook.install()
    if ISMoveableSpriteProps._lmionV3GaragePlacementInstalled then
        return false
    end

    ISMoveableSpriteProps._lmionV3GaragePlacementInstalled = true

    local previousHasFaces = ISMoveableSpriteProps.hasFaces
    local previousGetFaces = ISMoveableSpriteProps.getFaces
    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    local previousFindMultiSprite = ISMoveableSpriteProps.findInInventoryMultiSprite
    local previousCanPlace = ISMoveableSpriteProps.canPlaceMoveable
    local previousPlace = ISMoveableSpriteProps.placeMoveable

    ISMoveableSpriteProps.hasFaces = function(self)
        local faces = getRotationFaces(GarageMoveProps.getSegment(self))
        if faces ~= nil then
            return faces.N ~= faces.W
        end

        return previousHasFaces(self)
    end

    ISMoveableSpriteProps.getFaces = function(self)
        local faces = getRotationFaces(GarageMoveProps.getSegment(self))
        if faces ~= nil then
            return faces
        end

        return previousGetFaces(self)
    end

    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local faces = getRotationFaces(GarageMoveProps.getSegment(self))
        if faces ~= nil then
            return { faces.N, faces.W, faces.N, faces.W }
        end

        return previousGetIndexedFaces(self)
    end

    ISMoveableSpriteProps.findInInventoryMultiSprite = function(
        self,
        character,
        requestedName
    )
        local segment = GarageMoveProps.getSegment(self)
        if segment == nil then
            return previousFindMultiSprite(self, character, requestedName)
        end

        local index = tonumber(
            string.match(requestedName or "", "%((%d+)/3%)$")
        )
        if index == nil or index < 1 or index > 3 then
            return nil
        end

        if segment.facing == "W" then
            index = 4 - index
        end

        local itemType = segment.profile.itemTypes[index]
        local found = GarageParcelLookup.collect(character, itemType)
        local entry = found[1]

        return entry and entry.item or nil,
            entry and entry.source or nil
    end

    ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
        if GarageMoveProps.getSegment(self) == nil then
            return previousCanPlace(self, character, square, item)
        end

        local plan = buildFixedLengthPlan(self, character, square)
        return plan ~= nil and GaragePlacement.validate(character, plan)
    end

    ISMoveableSpriteProps.placeMoveable = function(
        self,
        character,
        square,
        origSpriteName,
        forceAllow
    )
        if GarageMoveProps.getSegment(self) == nil then
            return previousPlace(
                self,
                character,
                square,
                origSpriteName,
                forceAllow
            )
        end

        local plan = buildFixedLengthPlan(self, character, square)
        local placed = GaragePlacement.place(character, plan)

        if placed ~= nil
            and buildUtil ~= nil
            and buildUtil.setHaveConstruction ~= nil then
            for index = 1, #placed do
                buildUtil.setHaveConstruction(plan[index].square, true)
            end
        end

        if ISMoveableCursor ~= nil
            and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
            ISMoveableCursor.clearCacheForAllPlayers()
        end

        return placed
    end

    print("[LMION:DEV] Garage fixed-L3 toolbar placement hooks installed")
    return true
end

return GaragePlacementHook
