local DoorFrame = require "LMION/PZ/DoorFrame"

local StandardDoorFrame = {}

function StandardDoorFrame.existsAt(square, north)
    return DoorFrame.existsAt(square, north, "standard")
end

return StandardDoorFrame
