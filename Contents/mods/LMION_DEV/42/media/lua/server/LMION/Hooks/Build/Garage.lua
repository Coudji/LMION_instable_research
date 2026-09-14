require "BuildingObjects/ISBuildIsoEntity"

local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local GarageBuild = require "LMION/Services/Build/Garage/GarageBuild"
local GarageBuildFaceProxy = require "LMION/Services/Build/Garage/GarageBuildFaceProxy"
local GarageBuildRequirements = require "LMION/Services/Build/Garage/GarageBuildRequirements"
local GarageLengthState = require "LMION/Services/Build/Garage/GarageLengthState"

local function getProfile(buildObject)
    if buildObject == nil or buildObject.objectInfo == nil then
        return nil
    end

    return GarageBuild.getProfileFromObjectInfo(buildObject.objectInfo)
end

local function getLength(buildObject)
    local selected = buildObject and buildObject.lmionGarageLength or nil
    if selected ~= nil then
        return GarageBuild.normalizeLength(tonumber(selected))
    end

    local logic = buildObject and buildObject.buildPanelLogic or nil
    return GarageBuild.normalizeLength(
        GarageLengthState.getLengthFromLogic(logic)
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
        lmionGarageLength
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
            buildObject.lmionGarageLength = GarageBuild.normalizeLength(
                lmionGarageLength
                    or (logic and GarageLengthState.getLengthFromLogic(logic))
                    or GarageBuild.DefaultLength
            )
        end

        return buildObject
    end

    ISBuildIsoEntity.getFace = function(self)
        local face = previousGetFace(self)
        if getProfile(self) == nil or face == nil then
            return face
        end

        local length = getLength(self)
        if self._lmionGarageFaceSource ~= face
            or self._lmionGarageFaceLength ~= length then
            self._lmionGarageFaceSource = face
            self._lmionGarageFaceLength = length
            self._lmionGarageFaceProxy = GarageBuildFaceProxy.create(face, length)
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

        return GarageBuildRequirements.hasRequirements(
            self.character,
            profile,
            getLength(self),
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
            and not GarageBuildRequirements.hasRequirements(
                self.character,
                profile,
                getLength(self),
                getContainers(self)
            ) then
            return false
        end

        self._lmionGarageExtrasConsumed = false
        return previousCreate(self, x, y, z, north, sprite)
    end

    print("[LMION:DEV] variable Garage Build cursor hook installed")
end
