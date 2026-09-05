require "BuildingObjects/ISBuildIsoEntity"

local LargeGateBuildProfile = require "LMION/Services/Build/LargeGateBuildProfile"
local LargeGateFinalizer = require "LMION/Services/Build/LargeGateFinalizer"

local previousSetInfo = ISBuildIsoEntity.setInfo

local function getGameScript(buildObject)
    local objectInfo = buildObject and buildObject.objectInfo or nil
    local spriteScript = objectInfo and objectInfo:getScript() or nil
    return spriteScript and spriteScript:getParent() or nil
end

ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
    local profile = LargeGateBuildProfile.getByGameScript(getGameScript(self))
    local result = previousSetInfo(self, square, north, sprite, openSprite)

    if profile ~= nil then
        LargeGateFinalizer.finalize(
            square,
            profile,
            self.craftRecipe,
            self.character
        )
    end

    return result
end

print("[LMION:DEV] LargeGate Build finalizer hook installed")
