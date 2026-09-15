local GarageWidthPolicy = require "LMION/Domain/GarageWidthPolicy"
local GarageProfiles = require "LMION/Services/Common/Garage/Profiles"

local GarageBuild = {
    DefaultWidth = 3,
    MinWidth = 2,
    WidthModDataKey = "LMIONGarageBuildWidth",
}

function GarageBuild.normalizeWidth(width)
    width = math.max(
        GarageBuild.MinWidth,
        math.floor(tonumber(width) or GarageBuild.DefaultWidth)
    )

    local maximum = GarageWidthPolicy.getMaximumWidth()
    if maximum ~= nil then
        return math.min(width, maximum)
    end

    return width
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
