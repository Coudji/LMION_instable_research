require "BuildingObjects/ISBuildIsoEntity"

local GarageBuildFinalizer = require "LMION/Services/Build/Garage/GarageBuildFinalizer"
local LargeGateBuildProfile = require "LMION/Services/Build/LargeGate/Profile"
local LargeGateFinalizer = require "LMION/Services/Build/LargeGate/Finalizer"
local SingleTileDoorBuildProfile = require "LMION/Services/Build/SingleTileDoor/Profile"
local SingleTileDoorFinalizer = require "LMION/Services/Build/SingleTileDoor/Finalizer"

local function getGameScript(buildObject)
    local spriteScript = buildObject
        and buildObject.objectInfo
        and buildObject.objectInfo:getScript()
        or nil

    return spriteScript and spriteScript:getParent() or nil
end

if not ISBuildIsoEntity._lmionV3DoorSetInfoInstalled then
    ISBuildIsoEntity._lmionV3DoorSetInfoInstalled = true

    local previousSetInfo = ISBuildIsoEntity.setInfo

    ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
        local gameScript = getGameScript(self)
        local singleProfile = SingleTileDoorBuildProfile.getByGameScript(gameScript)
        local largeGateProfile = LargeGateBuildProfile.getByGameScript(gameScript)
        local garageProfile = GarageBuildFinalizer.getProfile(self)

        if garageProfile ~= nil
            and not GarageBuildFinalizer.beforeSetInfo(self, garageProfile) then
            error("LMION Garage extra-resource consumption failed")
        end

        local result = previousSetInfo(self, square, north, sprite, openSprite)

        if singleProfile ~= nil then
            SingleTileDoorFinalizer.finalize(
                square,
                singleProfile,
                self.craftRecipe,
                self.character
            )
        elseif largeGateProfile ~= nil then
            LargeGateFinalizer.finalize(
                square,
                largeGateProfile,
                self.craftRecipe,
                self.character
            )
        elseif garageProfile ~= nil then
            GarageBuildFinalizer.finalize(self, square, garageProfile)
        end

        return result
    end

    print("[LMION:DEV] shared door Build setInfo hook installed")
end
