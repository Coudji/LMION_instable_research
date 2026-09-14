require "Moveables/ISMoveableSpriteProps"

local GarageParcelLookup = {}

local function collectInventory(character, itemType)
    local found = {}
    local inventory = character and character:getInventory() or nil
    local items = inventory and inventory:getItems() or nil

    if items == nil then
        return found
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item ~= nil and item:getFullType() == itemType then
            found[#found + 1] = {
                item = item,
                source = inventory,
            }
        end
    end

    return found
end

function GarageParcelLookup.collect(character, itemType)
    local found = collectInventory(character, itemType)
    local playerSquare = character and character:getSquare() or nil

    if playerSquare == nil then
        return found
    end

    local radius = ISMoveableSpriteProps.multiSpriteFloorRadius or 3
    local startX = playerSquare:getX()
    local startY = playerSquare:getY()
    local z = playerSquare:getZ()

    for x = startX - radius, startX + radius do
        for y = startY - radius, startY + radius do
            local square = getCell():getGridSquare(x, y, z)
            local worldObjects = square and square:getWorldObjects() or nil

            if worldObjects ~= nil then
                for index = 0, worldObjects:size() - 1 do
                    local worldObject = worldObjects:get(index)

                    if instanceof(worldObject, "IsoWorldInventoryObject") then
                        local item = worldObject:getItem()
                        if item ~= nil and item:getFullType() == itemType then
                            found[#found + 1] = {
                                item = item,
                                source = "floor",
                                worldItem = worldObject,
                            }
                        end
                    end
                end
            end
        end
    end

    return found
end

return GarageParcelLookup
