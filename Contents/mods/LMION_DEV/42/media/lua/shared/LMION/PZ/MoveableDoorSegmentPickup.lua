local MoveableDoorSegmentPickup = {}

function MoveableDoorSegmentPickup.remove(character, square, object, item, createItem)
    if character == nil
        or square == nil
        or object == nil
        or item == nil
        or not instanceof(object, "IsoDoor")
        or object:getSquare() ~= square
        or not object:isObjectNoContainerOrEmpty() then
        return false
    end

    if createItem then
        square:AddWorldInventoryItem(
            item,
            ZombRandFloat(0.1, 0.9),
            ZombRandFloat(0.1, 0.9),
            0
        )
    end

    triggerEvent("OnObjectAboutToBeRemoved", object)
    square:transmitRemoveItemFromSquare(object)
    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)

    triggerEvent("OnContainerUpdate")
    IsoGenerator.updateGenerator(square)
    return true
end

return MoveableDoorSegmentPickup
