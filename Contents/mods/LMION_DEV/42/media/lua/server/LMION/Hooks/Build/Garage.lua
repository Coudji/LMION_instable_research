require "BuildingObjects/ISBuildIsoEntity"

local GarageBuild = require "LMION/Services/Build/GarageLengthState"

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
    return GarageBuild.normalizeLength(GarageBuild.getLengthFromLogic(logic))
end

local function getContainers(buildObject)
    local logic = buildObject and buildObject.buildPanelLogic or nil

    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end

    return buildObject and buildObject.containers or nil
end

if not ISBuildIsoEntity._lmionV3GarageBuildInstalled then
    ISBuildIsoEntity._lmionV3GarageBuildInstalled = true

    local previousNew = ISBuildIsoEntity.new
    local previousGetFace = ISBuildIsoEntity.getFace
    local previousIsValid = ISBuildIsoEntity.isValid
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
                    or (logic and GarageBuild.getLengthFromLogic(logic))
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
            self._lmionGarageFaceProxy = GarageBuild.createFaceProxy(face, length)
        end

        return self._lmionGarageFaceProxy
    end

    ISBuildIsoEntity.isValid = function(self, square)
        if not previousIsValid(self, square) then
            return false
        end

        local profile = getProfile(self)
        if profile == nil or self.character:isBuildCheat() then
            return true
        end

        return GarageBuild.hasRequirements(
            self.character,
            profile,
            getLength(self),
            getContainers(self)
        )
    end

    ISBuildIsoEntity.create = function(self, x, y, z, north, sprite)
        local profile = getProfile(self)

        if profile ~= nil
            and not self.character:isBuildCheat()
            and not GarageBuild.hasRequirements(
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
