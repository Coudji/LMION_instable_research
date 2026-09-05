local DoorFrame = require "LMION/PZ/DoorFrame"

local PairedDoorFrame = {}

function PairedDoorFrame.existsAt(square, north, member)
    if member == "left" then
        return DoorFrame.existsAt(square, north, "paired-left")
    end
    if member == "right" then
        return DoorFrame.existsAt(square, north, "paired-right")
    end

    return false
end

return PairedDoorFrame
