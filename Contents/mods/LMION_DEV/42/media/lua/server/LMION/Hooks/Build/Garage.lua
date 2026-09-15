require "BuildingObjects/ISBuildIsoEntity"

local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageFaceProxy = require "LMION/Services/Build/Garage/FaceProxy"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"

local function getProfile(buildObject)
    if buildObject == nil or buildObject.objectInfo == nil then
        return nil
    end

    return GarageBuild.getProfileFromObjectInfo(buildObject.objectInfo)
end

local function getWidth(buildObject)
    local selected = buildObject and buildObject.lmionGarageWidth or nil
    if selected ~= nil then
        return GarageBuild.normalizeWidth(tonumber(selected))
    end

    local logic = buildObject and buildObject.buildPanelLogic or nil
    return GarageBuild.normalizeWidth(
        GarageWidthState.getWidthFromLogic(logic)
    )
end

local function getContainers(buildObject)
    local logic = buildObject and buildObject.buildPanelLogic or nil

    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end

    return buildObject and buildObject.containers or nil
end

local function isPlacementValid(buildObject, square)
    if getProfile(buildObject) == nil then
        return true
    end

    local facing = buildObject.north == true and "N" or "W"
    return DoorPlacement.canPlaceUnframedAt(square, facing)
end

if not ISBuildIsoEntity._lmionV3GarageBuildInstalled then
    ISBuildIsoEntity._lmionV3GarageBuildInstalled = true

    local previousNew = ISBuildIsoEntity.new
    local previousGetFace = ISBuildIsoEntity.getFace
    local previousIsValid = ISBuildIsoEntity.isValid
    local previousIsValidPerSquare = ISBuildIsoEntity.isValidPerSquare
    local previousCreate = ISBuildIsoEntity.create

    ISBuildIsoEntity.new = function(
        self,
        character,
        objectInfo,
        nSprite,
        containersArg,
        logic,
        lmionGarageWidth
    )
        local buildObject = previousNew(
            self,
            character,
            objectInfo,
            nSprite,
            containersArg,
            logic
        )

        local profile = GarageBuild.getProfileFromObjectInfo(objectInfo)
        if profile ~= nil then
            buildObject.lmionGarageWidth = GarageBuild.normalizeWidth(
                lmionGarageWidth
                    or (logic and GarageWidthState.getWidthFromLogic(logic))
                    or GarageBuild.DefaultWidth
            )
        end

        return buildObject
    end

    ISBuildIsoEntity.getFace = function(self)
        local face = previousGetFace(self)
        if getProfile(self) == nil or face == nil then
            return face
        end

        local width = getWidth(self)
        if self._lmionGarageFaceSource ~= face
            or self._lmionGarageFaceWidth ~= width then
            self._lmionGarageFaceSource = face
            self._lmionGarageFaceWidth = width
            self._lmionGarageFaceProxy = GarageFaceProxy.create(face, width)
        end

        return self._lmionGarageFaceProxy
    end

    ISBuildIsoEntity.isValid = function(self, square)
        if not previousIsValid(self, square)
            or not isPlacementValid(self, square) then
            return false
        end

        local profile = getProfile(self)
        if profile == nil or self.character:isBuildCheat() then
            return true
        end

        return GarageRequirements.hasRequirements(
            self.character,
            profile,
            getWidth(self),
            getContainers(self)
        )
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

    ISBuildIsoEntity.create = function(self, x, y, z, north, sprite)
        local profile = getProfile(self)

        if profile ~= nil
            and not self.character:isBuildCheat()
            and not GarageRequirements.hasRequirements(
                self.character,
                profile,
                getWidth(self),
                getContainers(self)
            ) then
            return false
        end

        self._lmionGarageExtrasConsumed = false
        return previousCreate(self, x, y, z, north, sprite)
    end

    print("[LMION:DEV] variable-width Garage Build cursor hook installed")
end
