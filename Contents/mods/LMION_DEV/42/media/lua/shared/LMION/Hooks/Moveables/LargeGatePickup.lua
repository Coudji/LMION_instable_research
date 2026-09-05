require "Moveables/ISMoveableSpriteProps"

local LargeGateMembers = require "LMION/Services/Moveables/LargeGateMembers"
local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGateMoveProps"
local LargeGateParcelFactory = require "LMION/Services/Moveables/LargeGateParcelFactory"
local MoveableDoorSegmentPickup = require "LMION/PZ/MoveableDoorSegmentPickup"

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

local function canPickUpLeaf(character, members)
    for partIndex = 1, 2 do
        local member = members[partIndex]
        local object = member and member.object or nil
        local segment = member and member.segment or nil
        local profile = segment and segment.profile or nil
        local part = profile and profile.geometry[segment.facing][segment.leaf][partIndex] or nil
        local moveProps = part and ISMoveableSpriteProps.new(part.closed) or nil

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

local function createLeafParcels(members)
    local items = {}
    for partIndex = 1, 2 do
        local member = members[partIndex]
        local segment = member.segment
        items[partIndex] = LargeGateParcelFactory.create(
            segment.profile,
            segment,
            member.object
        )
        if items[partIndex] == nil then
            return nil
        end
    end
    return items
end

local function removeLeaf(character, members, items, createItem)
    for partIndex = 1, 2 do
        local member = members[partIndex]
        if not MoveableDoorSegmentPickup.remove(
            character,
            member.square,
            member.object,
            items[partIndex],
            createItem
        ) then
            return false
        end
    end
    return true
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

        local items = createLeafParcels(members)
        if items == nil then
            return false
        end

        print(string.format(
            "[LMION:DEV] LargeGate pickup started: definition=%s leaf=%s facing=%s open=%s",
            tostring(selectedSegment.definitionId),
            tostring(selectedSegment.leaf),
            tostring(selectedSegment.facing),
            tostring(selectedSegment.isOpen)
        ))

        if not removeLeaf(character, members, items, createItem) then
            print(string.format(
                "[LMION:DEV] LargeGate pickup failed during removal: definition=%s leaf=%s",
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
