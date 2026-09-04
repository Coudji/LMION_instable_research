local DoorObject = require "LMION/PZ/DoorObject"

local PlacedDoor = {}

function PlacedDoor.findBySprite(square, spriteName)
    if square == nil or type(spriteName) ~= "string" then
        return nil
    end

    local specialObjects = square:getSpecialObjects()
    for index = specialObjects:size() - 1, 0, -1 do
        local object = specialObjects:get(index)
        local sprite = object ~= nil and object:getSprite() or nil

        if DoorObject.isDoor(object)
            and sprite ~= nil
            and sprite:getName() == spriteName then
            return object
        end
    end

    return nil
end

return PlacedDoor
