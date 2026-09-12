local DoorObject = require "LMION/PZ/DoorObject"
local DoorFrame = require "LMION/PZ/DoorFrame"
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

local function hasAnyDoorFrameAt(square, north)
    return DoorFrame.existsAt(square, north, "standard")
        or DoorFrame.existsAt(square, north, "paired-left")
        or DoorFrame.existsAt(square, north, "paired-right")
end

local function hasObjectFrom(square, methodName, north)
    local method = square and square[methodName] or nil
    if method == nil then
        return false
    end

    local ok, object = pcall(method, square, north)
    return ok and object ~= nil
end

local function hasBlockingEdgeAt(square, north)
    -- An unframed opening still occupies a real N/W world edge. "No frame"
    -- means that no supporting frame is required; it does not permit replacing
    -- an existing wall, fence, frame, window or other edge object in-place.
    if hasAnyDoorFrameAt(square, north) then
        return true
    end

    if hasObjectFrom(square, "getWall", north)
        or hasObjectFrom(square, "getThumpableWall", north)
        or hasObjectFrom(square, "getHoppableWall", north)
        or hasObjectFrom(square, "getWindow", north)
        or hasObjectFrom(square, "getThumpableWindow", north)
        or hasObjectFrom(square, "getWindowFrame", north)
        or hasObjectFrom(square, "getGarageDoor", north) then
        return true
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

function DoorPlacement.canPlaceUnframedAt(square, facing)
    local north, reason = validateTarget(square, facing)
    if north == nil then
        return false, reason
    end

    if hasBlockingEdgeAt(square, north) then
        return false, "edge-already-occupied"
    end

    return true, "ok"
end

return DoorPlacement
