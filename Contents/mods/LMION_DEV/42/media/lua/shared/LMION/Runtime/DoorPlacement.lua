local DoorObject = require "LMION/PZ/DoorObject"
local PairedDoorFrame = require "LMION/PZ/PairedDoorFrame"
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

local function validateTarget(square, facing)
    if square == nil then
        return nil, "missing-square"
    end

    if facing ~= "N" and facing ~= "W" then
        return nil, "invalid-facing"
    end

    if square.isVehicleIntersecting ~= nil and square:isVehicleIntersecting() then
        return nil, "vehicle-intersection"
    end

    local north = facing == "N"
    if hasDoorAt(square, north) then
        return nil, "door-already-present"
    end

    return north, "ok"
end

function DoorPlacement.canPlaceSimpleAt(square, facing)
    local north, reason = validateTarget(square, facing)
    if north == nil then
        return false, reason
    end

    if not StandardDoorFrame.existsAt(square, north) then
        return false, "missing-standard-frame"
    end

    return true, "ok"
end

function DoorPlacement.canPlacePairedAt(square, facing, member)
    local north, reason = validateTarget(square, facing)
    if north == nil then
        return false, reason
    end

    if member ~= "left" and member ~= "right" then
        return false, "invalid-paired-member"
    end

    if not PairedDoorFrame.existsAt(square, north, member) then
        return false, "missing-paired-frame"
    end

    return true, "ok"
end

return DoorPlacement
