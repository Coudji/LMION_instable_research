local LargeGateParcelConsumption = {}

local function containsWorldObject(square, worldItem)
    local worldObjects = square and square:getWorldObjects() or nil
    if worldObjects == nil or worldItem == nil then
        return false
    end

    for index = 0, worldObjects:size() - 1 do
        if worldObjects:get(index) == worldItem then
            return true
        end
    end

    return false
end

local function consumeFloorItem(item)
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem:getSquare() or nil
    if worldItem == nil or square == nil then
        return false
    end

    -- Keep the same removal sequence used by vanilla Moveables and by the
    -- validated Legacy LargeGate path. The explicit check prevents LMION from
    -- reporting success while the world object is still present on the square.
    square:transmitRemoveItemFromSquare(worldItem)
    square:removeWorldObject(worldItem)

    if containsWorldObject(square, worldItem) then
        return false
    end

    item:setWorldItem(nil)
    return true
end

local function consumeContainerItem(item, container)
    if item == nil or container == nil then
        return false
    end

    container:Remove(item)
    sendRemoveItemFromContainer(container, item)
    return true
end

function LargeGateParcelConsumption.consume(item, source)
    if source == "floor" then
        return consumeFloorItem(item)
    end

    return consumeContainerItem(item, source)
end

return LargeGateParcelConsumption
