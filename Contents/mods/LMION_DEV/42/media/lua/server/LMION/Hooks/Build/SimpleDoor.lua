require "BuildingObjects/ISBuildIsoEntity"

local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local Resolver = require "LMION/Definitions/Resolver"
local SimpleDoorFinalizer = require "LMION/Services/Build/SimpleDoorFinalizer"

local PILOT_DEFINITION_ID = "Doors.Wood.WhitePanelDoor"
local PILOT_ENTITY_NAME = "WhitePanelDoor"
local PILOT_MOD_ID = "LMION_DEV"

local function getGameScript(buildObject)
    local spriteScript = buildObject
        and buildObject.objectInfo
        and buildObject.objectInfo:getScript()
        or nil

    return spriteScript and spriteScript:getParent() or nil
end

local function isPilotBuild(buildObject)
    if buildObject == nil or buildObject.craftRecipe == nil then
        return false
    end

    if buildObject.craftRecipe.getModID ~= nil
        and buildObject.craftRecipe:getModID() ~= PILOT_MOD_ID then
        return false
    end

    local gameScript = getGameScript(buildObject)
    return gameScript ~= nil
        and gameScript.getName ~= nil
        and gameScript:getName() == PILOT_ENTITY_NAME
end

local function getFacing(buildObject)
    if buildObject.north == true then
        return "N"
    end

    return "W"
end

local function isPilotPlacementValid(buildObject, square)
    if not isPilotBuild(buildObject) then
        return true
    end

    return DoorPlacement.canPlaceSimpleAt(square, getFacing(buildObject))
end

if ISBuildIsoEntity._lmionV3SimpleDoorBuildInstalled ~= true then
    ISBuildIsoEntity._lmionV3SimpleDoorBuildInstalled = true

    local originalIsValid = ISBuildIsoEntity.isValid
    local originalIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare
    local originalSetInfo = ISBuildIsoEntity.setInfo

    ISBuildIsoEntity.isValid = function(self, square)
        if not originalIsValid(self, square) then
            return false
        end

        return isPilotPlacementValid(self, square)
    end

    ISBuildIsoEntity.isValidPerSquare = function(self, square, tileInfo, requiresFloor, extendsN, extendsW)
        if not originalIsValidPerSquare(self, square, tileInfo, requiresFloor, extendsN, extendsW) then
            return false
        end

        return isPilotPlacementValid(self, square)
    end

    ISBuildIsoEntity.setInfo = function(self, square, north, sprite, openSprite)
        local pilot = isPilotBuild(self)
        local result = originalSetInfo(self, square, north, sprite, openSprite)

        if pilot then
            local definition = Resolver.resolveDefinition(PILOT_DEFINITION_ID)
            SimpleDoorFinalizer.finalize(
                square,
                definition,
                self.craftRecipe,
                self.character
            )
        end

        return result
    end

    print("[LMION:DEV] Simple Build hook installed: Doors.Wood.WhitePanelDoor")
end
