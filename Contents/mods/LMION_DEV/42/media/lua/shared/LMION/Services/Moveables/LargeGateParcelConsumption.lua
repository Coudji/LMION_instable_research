local LargeGateParcelConsumption = {}

local function consumeFloorItem(item)
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem:getSquare() or nil
    if worldItem == nil or square == nil then
        return false
    end

    square:transmitRemoveItemFromSquare(worldItem)
    square:removeWorldObject(worldItem)
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
