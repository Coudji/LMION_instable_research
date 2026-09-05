local DoorPlacement = require "LMION/Runtime/DoorPlacement"

local SingleTileDoorPlacement = {}

function SingleTileDoorPlacement.canPlace(profile, square, facing)
    if type(profile) ~= "table" then
        return false, "missing-profile"
    end

    if profile.doorType == "Simple" then
        return DoorPlacement.canPlaceSimpleAt(square, facing)
    end

    if profile.doorType == "Paired" then
        return DoorPlacement.canPlacePairedAt(square, facing, profile.member)
    end

    return false, "unsupported-door-type"
end

return SingleTileDoorPlacement
