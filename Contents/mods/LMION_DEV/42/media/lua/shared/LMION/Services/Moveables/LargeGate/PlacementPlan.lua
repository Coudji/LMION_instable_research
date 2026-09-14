local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local LargeGateParcelLookup = require "LMION/Services/Moveables/LargeGate/ParcelLookup"
local LargeGatePlacementSpace = require "LMION/Services/Common/LargeGatePlacementSpace"
local LargeGateProfiles = require "LMION/Services/Moveables/LargeGate/Profiles"

local LargeGatePlacementPlan = {}

local function getPartSprite(profile, facing, leaf, partIndex, isOpen)
    local part = profile.geometry[facing][leaf][partIndex]
    return isOpen and part.open or part.closed
end

local function isPartPlacementValid(character, square, item, closedSprite, facing)
    if square == nil or item == nil or closedSprite == nil then
        return false
    end

    local moveProps = ISMoveableSpriteProps.new(closedSprite)
    if moveProps == nil or not moveProps.isMoveable then
        return false
    end

    local wasMultiSprite = moveProps.isMultiSprite
    moveProps.isMultiSprite = false
    local vanillaValid = moveProps:canPlaceMoveableInternal(character, square, item)
    moveProps.isMultiSprite = wasMultiSprite

    if not vanillaValid then
        return false
    end

    return DoorPlacement.canPlaceUnframedAt(square, facing)
end

function LargeGatePlacementPlan.build(character, square, definitionId, facing, leaf, selectedPart)
    local profile = LargeGateProfiles.getByDefinitionId(definitionId)
    if profile == nil
        or square == nil
        or (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B")
        or (selectedPart ~= 1 and selectedPart ~= 2) then
        return nil
    end

    local anchor = LargeGatePlacementSpace.getAnchor(
        square,
        facing,
        leaf,
        selectedPart,
        "closed"
    )
    if anchor == nil then
        return nil
    end

    local operationallyValid = LargeGatePlacementSpace.validate(
        definitionId,
        anchor,
        facing,
        leaf
    )

    local plan = {
        profile = profile,
        definitionId = definitionId,
        facing = facing,
        leaf = leaf,
        selectedPart = selectedPart,
        anchor = anchor,
        targetState = "closed",
        isOpen = false,
        valid = operationallyValid == true,
    }

    for partIndex = 1, 2 do
        local parcel, source, worldItem = LargeGateParcelLookup.find(
            character,
            definitionId,
            leaf,
            partIndex
        )
        local targetSquare = LargeGatePlacementSpace.getPartSquare(
            anchor,
            facing,
            leaf,
            partIndex,
            "closed"
        )
        local closedSprite = getPartSprite(profile, facing, leaf, partIndex, false)
        local valid = isPartPlacementValid(
            character,
            targetSquare,
            parcel,
            closedSprite,
            facing
        )

        plan[partIndex] = {
            item = parcel,
            source = source,
            worldItem = worldItem,
            square = targetSquare,
            closedSprite = closedSprite,
            displaySprite = closedSprite,
            valid = valid,
        }

        if not valid then
            plan.valid = false
        end
    end

    return plan
end

return LargeGatePlacementPlan
