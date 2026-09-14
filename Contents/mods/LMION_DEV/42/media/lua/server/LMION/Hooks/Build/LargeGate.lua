require "BuildingObjects/ISBuildIsoEntity"

local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local LargeGateBuildProfile = require "LMION/Services/Build/LargeGate/Profile"
local LargeGatePlacementSpace = require "LMION/Services/Common/LargeGatePlacementSpace"

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

local function getFacing(buildObject)
    return buildObject.north == true and "N" or "W"
end

local function isClosedEdgeValid(buildObject, square)
    if getProfile(buildObject) == nil then
        return true
    end

    return DoorPlacement.canPlaceUnframedAt(square, getFacing(buildObject))
end

local function isOperationalPlacementValid(buildObject, square)
    local profile = getProfile(buildObject)
    if profile == nil then
        return true
    end

    local facing = getFacing(buildObject)
    local anchor = LargeGatePlacementSpace.getAnchor(
        square,
        facing,
        profile.leaf,
        1,
        "closed"
    )
    if anchor == nil then
        return false
    end

    return LargeGatePlacementSpace.validate(
        profile.definitionId,
        anchor,
        facing,
        profile.leaf
    )
end

if not ISBuildIsoEntity._lmionV3LargeGateBuildPlacementInstalled then
    ISBuildIsoEntity._lmionV3LargeGateBuildPlacementInstalled = true

    local previousIsValid = ISBuildIsoEntity.isValid
    local previousIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare

    ISBuildIsoEntity.isValid = function(self, square)
        return previousIsValid(self, square)
            and isOperationalPlacementValid(self, square)
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
        ) and isClosedEdgeValid(self, square)
    end

    print("[LMION:DEV] LargeGate Build operational placement hook installed")
end

return true
