local GarageLengthPolicy = require "LMION/Domain/GarageLengthPolicy"
local GarageProfiles = require "LMION/Services/Common/Garage/Profiles"

local GarageBuild = {
    DefaultLength = 3,
    MinLength = 2,
    LengthModDataKey = "LMIONGarageBuildLength",
}

function GarageBuild.normalizeLength(length)
    length = math.max(
        GarageBuild.MinLength,
        math.floor(tonumber(length) or GarageBuild.DefaultLength)
    )

    local maximum = GarageLengthPolicy.getMaximumLength()
    if maximum ~= nil then
        return math.min(length, maximum)
    end

    return length
end

local function getGameScript(objectInfo)
    local spriteScript = objectInfo
        and objectInfo.getScript
        and objectInfo:getScript()
        or nil

    return spriteScript and spriteScript:getParent() or nil
end

function GarageBuild.getProfileFromObjectInfo(objectInfo)
    return GarageProfiles.getByGameScript(getGameScript(objectInfo))
end

function GarageBuild.getProfileFromLogic(logic)
    local objectInfo = logic
        and logic.getSelectedBuildObject
        and logic:getSelectedBuildObject()
        or nil

    return GarageBuild.getProfileFromObjectInfo(objectInfo)
end

return GarageBuild
