local LargeGateParcel = require "LMION/Runtime/Moveables/LargeGateParcel"

local LargeGateParcelLookup = {}

local function matches(item, definitionId, leaf, partIndex)
    local identity = LargeGateParcel.readIdentity(item)
    return identity ~= nil
        and identity.definitionId == definitionId
        and identity.leaf == leaf
        and identity.partIndex == partIndex
end

local function findInInventory(character, definitionId, leaf, partIndex)
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil
    if items == nil then
        return nil, nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if matches(item, definitionId, leaf, partIndex) then
            return item, inventory
        end
    end

    return nil, nil
end

local function findOnFloor(character, definitionId, leaf, partIndex)
    local playerSquare = character and character:getSquare() or nil
    if playerSquare == nil then
        return nil, nil
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local z = playerSquare:getZ()

    for x = playerSquare:getX() - radius, playerSquare:getX() + radius do
        for y = playerSquare:getY() - radius, playerSquare:getY() + radius do
            local square = getCell():getGridSquare(x, y, z)
            local worldObjects = square and square:getWorldObjects() or nil
            if worldObjects ~= nil then
                for index = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(index)
                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if matches(item, definitionId, leaf, partIndex) then
                            return item, "floor"
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

function LargeGateParcelLookup.find(character, definitionId, leaf, partIndex, preferred)
    if preferred ~= nil and matches(preferred, definitionId, leaf, partIndex) then
        local container = preferred:getContainer()
        if container ~= nil then
            return preferred, container
        end

        local worldItem = preferred.getWorldItem and preferred:getWorldItem() or nil
        if worldItem ~= nil and worldItem:getSquare() ~= nil then
            return preferred, "floor"
        end
    end

    local item, source = findInInventory(character, definitionId, leaf, partIndex)
    if item ~= nil then
        return item, source
    end

    return findOnFloor(character, definitionId, leaf, partIndex)
end

function LargeGateParcelLookup.matches(item, definitionId, leaf, partIndex)
    return matches(item, definitionId, leaf, partIndex)
end

return LargeGateParcelLookup
