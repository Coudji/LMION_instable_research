require "BuildingObjects/ISBuildIsoEntity"

local SingleTileDoorBuildProfile = require "LMION/Services/Build/SingleTileDoor/Profile"
local SingleTileDoorPlacement = require "LMION/Services/Common/SingleTileDoor/Placement"

local MOD_ID = "LMION_DEV"

local function getGameScript(buildObject)
    local spriteScript = nil

    if buildObject ~= nil and buildObject.objectInfo ~= nil then
        spriteScript = buildObject.objectInfo:getScript()
    end

    return spriteScript and spriteScript:getParent() or nil
end

local function getProfile(buildObject)
    if buildObject == nil or buildObject.craftRecipe == nil then
        return nil
    end

    if buildObject.craftRecipe.getModID ~= nil
        and buildObject.craftRecipe:getModID() ~= MOD_ID then
        return nil
    end

    return SingleTileDoorBuildProfile.getByGameScript(
        getGameScript(buildObject)
    )
end

local function getFacing(buildObject)
    if buildObject.north == true then
        return "N"
    end

    return "W"
end

local function isPlacementValid(buildObject, square)
    local profile = getProfile(buildObject)
    if profile == nil then
        return true
    end

    return SingleTileDoorPlacement.canPlace(
        profile,
        square,
        getFacing(buildObject)
    )
end

if not ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled then
    ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled = true

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

    print("[LMION:DEV] Single-tile Build validation hook installed")
end