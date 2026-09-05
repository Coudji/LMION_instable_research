require "BuildingObjects/ISBuildIsoEntity"

local SingleTileDoorBuildProfile = require "LMION/Services/Build/SingleTileDoorBuildProfile"
local SingleTileDoorFinalizer = require "LMION/Services/Build/SingleTileDoorFinalizer"
local SingleTileDoorPlacement = require "LMION/Services/Moveables/SingleTileDoorPlacement"

local MOD_ID = "LMION_DEV"

local function getGameScript(buildObject)
    local spriteScript = buildObject
        and buildObject.objectInfo
        and buildObject.objectInfo:getScript()
        or nil

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

    return SingleTileDoorBuildProfile.getByGameScript(getGameScript(buildObject))
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

    return SingleTileDoorPlacement.canPlace(profile, square, getFacing(buildObject))
end

if ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled ~= true then
    ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled = true

    local originalIsValid = ISBuildIsoEntity.isValid
    local originalIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare
    local originalSetInfo = ISBuildIsoEntity.setInfo

    ISBuildIsoEntity.isValid = function(self, square)
        if not originalIsValid(self, square) then
            return false
        end

        return isPlacementValid(self, square)
    end

    ISBuildIsoEntity.isValidPerSquare = function(self, square, tileInfo, requiresFloor, extendsN, extendsW)
        if not originalIsValidPerSquare(self, square, tileInfo, requiresFloor, extendsN, extendsW) then
            return false
        end

        return isPlacementValid(self, square)
    end

    ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
        local profile = getProfile(self)
        local result = originalSetInfo(self, square, north, sprite, openSprite)

        if profile ~= nil then
            SingleTileDoorFinalizer.finalize(
                square,
                profile,
                self.craftRecipe,
                self.character
            )
        end

        return result
    end

    print("[LMION:DEV] Single-tile Build hook installed")
end
