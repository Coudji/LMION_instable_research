require "BuildingObjects/ISBuildIsoEntity"

local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local LargeGateBuildProfile = require "LMION/Services/Build/LargeGate/Profile"

local function getProfile(buildObject)
    if buildObject == nil or buildObject.objectInfo == nil then
        return nil
    end

    local spriteConfig = buildObject.objectInfo:getScript()
    if spriteConfig == nil then
        return nil
    end

    return LargeGateBuildProfile.getByGameScript(spriteConfig:getParent())
end

local function isPlacementValid(buildObject, square)
    if getProfile(buildObject) == nil then
        return true
    end

    local facing = buildObject.north == true and "N" or "W"
    return DoorPlacement.canPlaceUnframedAt(square, facing)
end

if not ISBuildIsoEntity._lmionV3LargeGateBuildPlacementInstalled then
    ISBuildIsoEntity._lmionV3LargeGateBuildPlacementInstalled = true

    local previousIsValid = ISBuildIsoEntity.isValid
    local previousIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare

    ISBuildIsoEntity.isValid = function(self, square)
        return previousIsValid(self, square)
            and isPlacementValid(self, square)
    end

    ISBuildIsoEntity.isValidPerSquare = function(
        self,
        square,
        tileInfo,
        requiresFloor,
        extendsN,
        extendsW
    )
        return previousIsValidPerSquare(
            self,
            square,
            tileInfo,
            requiresFloor,
            extendsN,
            extendsW
        ) and isPlacementValid(self, square)
    end

    print("[LMION:DEV] LargeGate Build edge validation hook installed")
end

return true
