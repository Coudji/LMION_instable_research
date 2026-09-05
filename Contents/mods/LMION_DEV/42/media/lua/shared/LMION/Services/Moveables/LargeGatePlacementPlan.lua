local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local LargeGateParcelLookup = require "LMION/Services/Moveables/LargeGateParcelLookup"
local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"
local LargeGateWorldState = require "LMION/Services/Moveables/LargeGateWorldState"

local LargeGatePlacementPlan = {}

local function getPartSprite(profile, facing, leaf, partIndex, isOpen)
    local part = profile.geometry[facing][leaf][partIndex]
    return isOpen and part.open or part.closed
end

local function isPartPlacementValid(character, square, item, closedSprite, facing, isOpen)
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

    if isOpen and not moveProps:isFreeTile(square) then
        return false
    end

    return DoorPlacement.canPlaceUnframedAt(square, facing)
end

function LargeGatePlacementPlan.build(character, square, item, definitionId, facing, leaf, selectedPart)
    local profile = LargeGateProfiles.getByDefinitionId(definitionId)
    if profile == nil
        or square == nil
        or (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B")
        or (selectedPart ~= 1 and selectedPart ~= 2) then
        return nil
    end

    local anchor = LargeGateWorldState.getAnchor(square, facing, leaf, selectedPart)
    if anchor == nil then
        return nil
    end

    local partnerState = LargeGateWorldState.getPartnerState(profile, anchor, facing, leaf)
    if partnerState == "incoherent" then
        return nil
    end

    local targetState = partnerState == "open" and "open" or "closed"
    local isOpen = targetState == "open"
    local plan = {
        profile = profile,
        definitionId = definitionId,
        facing = facing,
        leaf = leaf,
        selectedPart = selectedPart,
        anchor = anchor,
        partnerState = partnerState,
        targetState = targetState,
        isOpen = isOpen,
        valid = true,
    }

    for partIndex = 1, 2 do
        local parcel, source = LargeGateParcelLookup.find(
            character,
            definitionId,
            leaf,
            partIndex,
            partIndex == selectedPart and item or nil
        )
        local targetSquare = LargeGateWorldState.getPartSquare(
            anchor,
            facing,
            leaf,
            partIndex,
            targetState
        )
        local closedSprite = getPartSprite(profile, facing, leaf, partIndex, false)
        local displaySprite = getPartSprite(profile, facing, leaf, partIndex, isOpen)
        local valid = isPartPlacementValid(
            character,
            targetSquare,
            parcel,
            closedSprite,
            facing,
            isOpen
        )

        plan[partIndex] = {
            item = parcel,
            source = source,
            square = targetSquare,
            closedSprite = closedSprite,
            displaySprite = displaySprite,
            valid = valid,
        }

        if not valid then
            plan.valid = false
        end
    end

    return plan
end

return LargeGatePlacementPlan
