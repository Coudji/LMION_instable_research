local DoorObject = require "LMION/PZ/DoorObject"
local StandardDoorFrame = require "LMION/PZ/StandardDoorFrame"

local DoorPlacement = {}

local function hasDoorAt(square, north)
    local specialObjects = square:getSpecialObjects()

    for index = 0, specialObjects:size() - 1 do
        local object = specialObjects:get(index)
        if DoorObject.isDoor(object) and DoorObject.getNorth(object) == north then
            return true
        end
    end

    return false
end

function DoorPlacement.canPlaceSimpleAt(square, facing)
    if square == nil then
        return false, "missing-square"
    end

    if facing ~= "N" and facing ~= "W" then
        return false, "invalid-facing"
    end

    if square.isVehicleIntersecting ~= nil and square:isVehicleIntersecting() then
        return false, "vehicle-intersection"
    end

    local north = facing == "N"

    if hasDoorAt(square, north) then
        return false, "door-already-present"
    end

    if not StandardDoorFrame.existsAt(square, north) then
        return false, "missing-standard-frame"
    end

    return true, "ok"
end

return DoorPlacement
