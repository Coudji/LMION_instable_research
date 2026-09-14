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

local function consumeFloorItem(item, worldItem)
    local selectedWorldItem = worldItem or (item and item.getWorldItem and item:getWorldItem() or nil)
    local square = selectedWorldItem and selectedWorldItem:getSquare() or nil
    if selectedWorldItem == nil or square == nil then
        return false
    end

    square:transmitRemoveItemFromSquare(selectedWorldItem)
    square:removeWorldObject(selectedWorldItem)

    if containsWorldObject(square, selectedWorldItem) then
        return false
    end

    if item ~= nil and item.setWorldItem ~= nil and item:getWorldItem() == selectedWorldItem then
        item:setWorldItem(nil)
    end

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

function LargeGateParcelConsumption.consume(item, source, worldItem)
    if source == "floor" then
        return consumeFloorItem(item, worldItem)
    end

    return consumeContainerItem(item, source)
end

return LargeGateParcelConsumption
