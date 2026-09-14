require "Moveables/ISMoveableSpriteProps"

local GarageLengthPolicy = require "LMION/Domain/GarageLengthPolicy"
local GarageParcelLookup = require "LMION/Services/Moveables/Garage/ParcelLookup"
local GarageProfiles = require "LMION/Services/Moveables/Garage/Profiles"
local SingleTileDoorPlacementFinalizer = require "LMION/Services/Moveables/SingleTileDoor/PlacementFinalizer"

local GaragePlacement = {}

local function collectAvailableParcels(character, profile)
    return {
        START = GarageParcelLookup.collect(character, profile.itemTypes[1]),
        MIDDLE = GarageParcelLookup.collect(character, profile.itemTypes[2]),
        END = GarageParcelLookup.collect(character, profile.itemTypes[3]),
    }
end

local function getMaximumLength(parts)
    if parts == nil
        or #parts.START < 1
        or #parts.END < 1 then
        return nil
    end

    local maximum = 2 + #parts.MIDDLE
    local policyMaximum = GarageLengthPolicy.getMaximumLength()

    if policyMaximum ~= nil then
        maximum = math.min(maximum, policyMaximum)
    end

    return maximum
end

function GaragePlacement.getMaximumAvailableLength(character, definitionId)
    local profile = GarageProfiles.getByDefinitionId(definitionId)
    if profile == nil then
        return nil
    end

    return getMaximumLength(collectAvailableParcels(character, profile))
end

function GaragePlacement.buildPlan(
    character,
    definitionId,
    length,
    facing,
    startSquare
)
    local profile = GarageProfiles.getByDefinitionId(definitionId)
    length = tonumber(length)

    if profile == nil
        or startSquare == nil
        or (facing ~= "N" and facing ~= "W") then
        return nil
    end

    local parts = collectAvailableParcels(character, profile)
    local maximum = getMaximumLength(parts)

    if maximum == nil
        or length == nil
        or length ~= math.floor(length)
        or length < 2
        or length > maximum
        or not GarageLengthPolicy.isLengthAllowed(length) then
        return nil
    end

    local plan = {
        length = length,
        definitionId = definitionId,
        facing = facing,
        profile = profile,
    }

    local middleIndex = 1

    for position = 1, length do
        local role = nil
        local parcel = nil

        if position == 1 then
            role = "START"
            parcel = parts.START[1]
        elseif position == length then
            role = "END"
            parcel = parts.END[1]
        else
            role = "MIDDLE"
            parcel = parts.MIDDLE[middleIndex]
            middleIndex = middleIndex + 1
        end

        local x = startSquare:getX()
        local y = startSquare:getY()

        if facing == "N" then
            x = x + position - 1
        else
            y = y - position + 1
        end

        local square = getCell():getGridSquare(x, y, startSquare:getZ())
        local spriteName = profile.geometry[facing][role].closed

        if parcel == nil or square == nil or spriteName == nil then
            return nil
        end

        plan[position] = {
            item = parcel.item,
            source = parcel.source,
            worldItem = parcel.worldItem,
            square = square,
            spriteName = spriteName,
            role = role,
        }
    end

    return plan
end

local function getMoveProps(entry)
    local moveProps = ISMoveableSpriteProps.new(entry.spriteName)
    if moveProps ~= nil then
        moveProps.isMultiSprite = false
    end

    return moveProps
end

local function isSourceValid(entry)
    if entry.source == "floor" then
        return entry.worldItem ~= nil
            and entry.worldItem:getSquare() ~= nil
            and entry.worldItem:getItem() == entry.item
    end

    return entry.source ~= nil
        and entry.item ~= nil
        and entry.item:getContainer() == entry.source
end

function GaragePlacement.validate(character, plan)
    if character == nil or plan == nil then
        return false
    end

    for index = 1, plan.length do
        local entry = plan[index]
        local moveProps = getMoveProps(entry)

        if moveProps == nil
            or not isSourceValid(entry)
            or entry.square == nil
            or not moveProps:canPlaceMoveableInternal(
                character,
                entry.square,
                entry.item
            ) then
            return false
        end
    end

    return true
end

local function removePlacedObjects(objects)
    for index = #objects, 1, -1 do
        local object = objects[index]
        local square = object and object:getSquare() or nil

        if object ~= nil and square ~= nil then
            square:transmitRemoveItemFromSquare(object)
            square:RecalcAllWithNeighbours(true)
        end
    end
end

local function consumeParcel(entry)
    if entry.source == "floor" then
        local worldItem = entry.worldItem
        local square = worldItem and worldItem:getSquare() or nil

        if worldItem == nil or square == nil then
            return false
        end

        square:transmitRemoveItemFromSquare(worldItem)
        square:removeWorldObject(worldItem)

        if entry.item:getWorldItem() == worldItem then
            entry.item:setWorldItem(nil)
        end

        return true
    end

    if entry.source ~= nil and entry.source.Remove ~= nil then
        entry.source:Remove(entry.item)
        sendRemoveItemFromContainer(entry.source, entry.item)
        return true
    end

    return false
end

function GaragePlacement.place(character, plan)
    if not GaragePlacement.validate(character, plan) then
        return nil
    end

    local placed = {}

    for index = 1, plan.length do
        local entry = plan[index]
        local moveProps = getMoveProps(entry)
        local rawObject = moveProps and moveProps:placeMoveableInternal(
            entry.square,
            entry.item,
            entry.spriteName
        ) or nil

        local finalObject = rawObject and SingleTileDoorPlacementFinalizer.finalize(
            entry.square,
            rawObject,
            entry.item,
            entry.spriteName,
            plan.profile
        ) or nil

        if finalObject == nil then
            removePlacedObjects(placed)

            if rawObject ~= nil and rawObject:getSquare() ~= nil then
                removePlacedObjects({ rawObject })
            end

            return nil
        end

        placed[index] = finalObject
    end

    for index = 1, plan.length do
        if not consumeParcel(plan[index]) then
            print("[LMION:DEV] Garage parcel consumption failed after completed placement")
        end
    end

    return placed
end

return GaragePlacement
