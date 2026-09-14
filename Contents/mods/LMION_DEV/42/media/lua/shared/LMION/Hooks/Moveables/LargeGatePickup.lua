require "Moveables/ISMoveableSpriteProps"

local LargeGateMembers = require "LMION/Services/Common/LargeGateMembers"
local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGateMoveProps"

local LargeGatePickupHook = {}

local function getSelectedObject(moveProps, square, object)
    if object ~= nil then
        return object
    end
    if square == nil then
        return nil
    end
    return moveProps:findOnSquare(square, moveProps.spriteName)
end

local function getClosedSprite(segment, partIndex)
    local profile = segment and segment.profile or nil
    local face = profile and profile.geometry[segment.facing] or nil
    local parts = face and face[segment.leaf] or nil
    local part = parts and parts[partIndex] or nil
    return part and part.closed or nil
end

local function canPickUpLeaf(character, members)
    for partIndex = 1, 2 do
        local member = members[partIndex]
        local object = member and member.object or nil
        local segment = member and member.segment or nil
        local closedSprite = getClosedSprite(segment, partIndex)
        local moveProps = closedSprite and ISMoveableSpriteProps.new(closedSprite) or nil

        if object == nil
            or moveProps == nil
            or not object:isObjectNoContainerOrEmpty()
            or not moveProps:canPickUpMoveableInternal(
                character,
                member.square,
                object,
                true
            ) then
            return false
        end
    end

    return true
end

local function pickUpLeaf(character, members, createItem)
    local items = {}

    for partIndex = 1, 2 do
        local member = members[partIndex]
        local closedSprite = getClosedSprite(member.segment, partIndex)
        local moveProps = closedSprite and ISMoveableSpriteProps.new(closedSprite) or nil
        if moveProps == nil then
            return nil
        end

        -- Legacy's validated LargeGate path lets vanilla own the actual
        -- Moveable item lifecycle for each physical member. Keeping
        -- isMultiSprite=true makes vanilla deliver each parcel to the floor.
        moveProps.isMultiSprite = true
        items[partIndex] = moveProps:pickUpMoveableInternal(
            character,
            member.square,
            member.object,
            nil,
            closedSprite,
            createItem,
            false
        )

        if items[partIndex] == nil then
            return nil
        end
    end

    return items
end

function LargeGatePickupHook.install()
    if ISMoveableSpriteProps._lmionV3LargeGatePickupInstalled == true then
        return false
    end

    ISMoveableSpriteProps._lmionV3LargeGatePickupInstalled = true

    local previousCanPickUp = ISMoveableSpriteProps.canPickUpMoveable
    local previousPickUp = ISMoveableSpriteProps.pickUpMoveable

    ISMoveableSpriteProps.canPickUpMoveable = function(self, character, square, object)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment == nil then
            return previousCanPickUp(self, character, square, object)
        end

        local selected = getSelectedObject(self, square, object)
        local selectedSegment = LargeGateMembers.getSegmentForObject(selected)
        if selectedSegment == nil
            or selectedSegment.definitionId ~= segment.definitionId
            or selectedSegment.leaf ~= segment.leaf
            or selectedSegment.partIndex ~= segment.partIndex then
            return false
        end

        local members = LargeGateMembers.getLeaf(selected, selectedSegment)
        return members ~= nil and canPickUpLeaf(character, members)
    end

    ISMoveableSpriteProps.pickUpMoveable = function(self, character, square, createItem, forceAllow)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment == nil then
            return previousPickUp(self, character, square, createItem, forceAllow)
        end

        local selected = getSelectedObject(self, square, nil)
        local selectedSegment = LargeGateMembers.getSegmentForObject(selected)
        if selectedSegment == nil then
            return false
        end

        if not forceAllow
            and not character:isMovablesCheat()
            and not ISMoveableDefinitions.cheat
            and not self:canPickUpMoveable(character, square, selected) then
            return false
        end

        local members = LargeGateMembers.getLeaf(selected, selectedSegment)
        if members == nil then
            return false
        end

        print(string.format(
            "[LMION:DEV] LargeGate pickup started: definition=%s leaf=%s facing=%s open=%s",
            tostring(selectedSegment.definitionId),
            tostring(selectedSegment.leaf),
            tostring(selectedSegment.facing),
            tostring(selectedSegment.isOpen)
        ))

        local items = pickUpLeaf(character, members, createItem)
        if items == nil then
            print(string.format(
                "[LMION:DEV] LargeGate pickup failed during vanilla member pickup: definition=%s leaf=%s",
                tostring(selectedSegment.definitionId),
                tostring(selectedSegment.leaf)
            ))
            return false
        end

        if ISMoveableCursor ~= nil and ISMoveableCursor.clearCacheForAllPlayers ~= nil then
            ISMoveableCursor.clearCacheForAllPlayers()
        end

        print(string.format(
            "[LMION:DEV] LargeGate pickup completed: definition=%s leaf=%s parcels=2",
            tostring(selectedSegment.definitionId),
            tostring(selectedSegment.leaf)
        ))
        return items
    end

    print("[LMION:DEV] LargeGate pickup hooks installed")
    return true
end

return LargeGatePickupHook
