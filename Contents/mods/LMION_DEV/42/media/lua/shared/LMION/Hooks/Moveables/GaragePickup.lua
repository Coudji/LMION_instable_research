require "Moveables/ISMoveableSpriteProps"

local GarageMembers = require "LMION/Services/Moveables/Garage/Members"
local GarageMoveProps = require "LMION/Services/Moveables/Garage/MoveProps"

local GaragePickup = {}

local function getSelectedObject(moveProps, square, object)
    if object ~= nil then
        return object
    end

    if square == nil then
        return nil
    end

    return moveProps:findOnSquare(square, moveProps.spriteName)
end

local function canPickChain(character, members)
    for _, member in ipairs(members) do
        local props = ISMoveableSpriteProps.new(member.closedSpriteName)
        if props == nil or not member.object:isObjectNoContainerOrEmpty() then
            return false
        end

        local wasMultiSprite = props.isMultiSprite
        props.isMultiSprite = false
        local canPick = props:canPickUpMoveableInternal(
            character,
            member.square,
            member.object,
            true
        )
        props.isMultiSprite = wasMultiSprite

        if not canPick then
            return false
        end
    end

    return true
end

function GaragePickup.install()
    if ISMoveableSpriteProps._lmionV3GaragePickupInstalled then
        return false
    end

    ISMoveableSpriteProps._lmionV3GaragePickupInstalled = true

    local previousCanPickUp = ISMoveableSpriteProps.canPickUpMoveable
    local previousPickUp = ISMoveableSpriteProps.pickUpMoveable

    ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
        local segment = GarageMoveProps.getSegment(self)
        if segment == nil then
            return previousCanPickUp(self, character, square, object)
        end

        local selectedObject = getSelectedObject(self, square, object)
        local members = GarageMembers.getMembers(
            selectedObject,
            segment.definitionId
        )

        return members ~= nil and canPickChain(character, members)
    end

    ISMoveableSpriteProps.pickUpMoveable = function(
        self,
        character,
        square,
        createItem,
        forceAllow
    )
        local segment = GarageMoveProps.getSegment(self)
        if segment == nil then
            return previousPickUp(self, character, square, createItem, forceAllow)
        end

        local selectedObject = getSelectedObject(self, square, nil)
        if selectedObject == nil then
            return false
        end

        if not forceAllow
            and not character:isMovablesCheat()
            and not ISMoveableDefinitions.cheat
            and not self:canPickUpMoveable(character, square, selectedObject) then
            return false
        end

        local members = GarageMembers.getMembers(
            selectedObject,
            segment.definitionId
        )
        if members == nil then
            return false
        end

        local items = {}
        for index, member in ipairs(members) do
            local props = ISMoveableSpriteProps.new(member.closedSpriteName)
            if props == nil then
                return false
            end

            props.isMultiSprite = true
            items[index] = props:pickUpMoveableInternal(
                character,
                member.square,
                member.object,
                nil,
                member.closedSpriteName,
                createItem,
                forceAllow
            )

            if items[index] == nil then
                return false
            end
        end

        if ISMoveableCursor ~= nil
            and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
            ISMoveableCursor.clearCacheForAllPlayers()
        end

        print(string.format(
            "[LMION:DEV] Garage pickup completed: definition=%s parcels=%d",
            tostring(segment.definitionId),
            #members
        ))

        return items
    end

    print("[LMION:DEV] Garage pickup hooks installed")
    return true
end

return GaragePickup
