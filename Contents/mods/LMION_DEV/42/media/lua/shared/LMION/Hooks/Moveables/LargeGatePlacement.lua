require "Moveables/ISMoveableSpriteProps"

local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGateMoveProps"
local LargeGateParcelConsumption = require "LMION/Services/Moveables/LargeGateParcelConsumption"
local LargeGateParcelLookup = require "LMION/Services/Moveables/LargeGateParcelLookup"
local LargeGatePlacementFinalizer = require "LMION/Services/Moveables/LargeGatePlacementFinalizer"
local LargeGatePlacementPlan = require "LMION/Services/Moveables/LargeGatePlacementPlan"

local LargeGatePlacementHook = {}

local function buildPlan(moveProps, character, square, item)
    local segment = LargeGateMoveProps.getSegment(moveProps)
    if segment == nil then
        return nil
    end

    return LargeGatePlacementPlan.build(
        character,
        square,
        item,
        segment.definitionId,
        moveProps.lmionLargeGateFacing,
        moveProps.lmionLargeGateLeaf,
        moveProps.lmionLargeGatePart
    )
end

local function placePart(entry, plan, partIndex)
    local moveProps = ISMoveableSpriteProps.new(entry.closedSprite)
    if moveProps == nil then
        return nil
    end

    local wasMultiSprite = moveProps.isMultiSprite
    moveProps.isMultiSprite = false
    local object = moveProps:placeMoveableInternal(
        entry.square,
        entry.item,
        entry.closedSprite
    )
    moveProps.isMultiSprite = wasMultiSprite

    if object == nil then
        return nil
    end

    return LargeGatePlacementFinalizer.finalize(
        object,
        entry,
        plan,
        partIndex
    )
end

local function placePlan(plan)
    if plan == nil or plan.valid ~= true then
        return false
    end

    local placed = {}
    for partIndex = 1, 2 do
        placed[partIndex] = placePart(plan[partIndex], plan, partIndex)
        if placed[partIndex] == nil then
            print(string.format(
                "[LMION:DEV] LargeGate placement failed: definition=%s leaf=%s part=%d reason=finalization",
                tostring(plan.definitionId),
                tostring(plan.leaf),
                partIndex
            ))
            return false
        end
    end

    for partIndex = 1, 2 do
        local entry = plan[partIndex]
        if not LargeGateParcelConsumption.consume(entry.item, entry.source) then
            print(string.format(
                "[LMION:DEV] LargeGate parcel consumption failed: definition=%s leaf=%s part=%d",
                tostring(plan.definitionId),
                tostring(plan.leaf),
                partIndex
            ))
            return false
        end

        if buildUtil ~= nil and buildUtil.setHaveConstruction ~= nil then
            buildUtil.setHaveConstruction(entry.square, true)
        end
    end

    if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
        ISMoveableCursor.clearCacheForAllPlayers()
    end

    print(string.format(
        "[LMION:DEV] LargeGate placement completed: definition=%s leaf=%s facing=%s open=%s",
        tostring(plan.definitionId),
        tostring(plan.leaf),
        tostring(plan.facing),
        tostring(plan.isOpen)
    ))

    return placed
end

function LargeGatePlacementHook.install()
    if ISMoveableSpriteProps._lmionV3LargeGatePlacementInstalled == true then
        return false
    end

    ISMoveableSpriteProps._lmionV3LargeGatePlacementInstalled = true

    local previousFindMultiSprite = ISMoveableSpriteProps.findInInventoryMultiSprite
    local previousCanPlace = ISMoveableSpriteProps.canPlaceMoveable
    local previousPlace = ISMoveableSpriteProps.placeMoveable

    ISMoveableSpriteProps.findInInventoryMultiSprite = function(self, character, requestedName)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment == nil then
            return previousFindMultiSprite(self, character, requestedName)
        end

        local partIndex = tonumber(string.match(requestedName or "", "%((%d+)/2%)$"))
        if partIndex ~= 1 and partIndex ~= 2 then
            return nil
        end

        return LargeGateParcelLookup.find(
            character,
            segment.definitionId,
            self.lmionLargeGateLeaf,
            partIndex,
            nil
        )
    end

    ISMoveableSpriteProps.canPlaceMoveable = function(self, character, square, item)
        if LargeGateMoveProps.getSegment(self) == nil then
            return previousCanPlace(self, character, square, item)
        end

        local plan = buildPlan(self, character, square, item)
        return plan ~= nil and plan.valid == true
    end

    ISMoveableSpriteProps.placeMoveable = function(self, character, square, origSpriteName, forceAllow)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment == nil then
            return previousPlace(self, character, square, origSpriteName, forceAllow)
        end

        local selectedItem = LargeGateParcelLookup.find(
            character,
            segment.definitionId,
            self.lmionLargeGateLeaf,
            self.lmionLargeGatePart,
            nil
        )
        local plan = buildPlan(self, character, square, selectedItem)

        print(string.format(
            "[LMION:DEV] LargeGate placement started: definition=%s leaf=%s facing=%s partner=%s",
            tostring(segment.definitionId),
            tostring(self.lmionLargeGateLeaf),
            tostring(self.lmionLargeGateFacing),
            tostring(plan and plan.partnerState or nil)
        ))

        return placePlan(plan)
    end

    print("[LMION:DEV] LargeGate placement hooks installed")
    return true
end

return LargeGatePlacementHook
