require "BuildingObjects/ISBuildIsoEntity"

local DoorTypes = require "LMION/Domain/DoorTypes"
local DefinitionLookup = require "LMION/Services/DefinitionLookup"
local LargeGateBuildProfile = require "LMION/Services/Build/LargeGate/Profile"

local function getGameScript(objectInfo)
    local spriteConfig = objectInfo
        and objectInfo.getScript
        and objectInfo:getScript()
        or nil

    if spriteConfig == nil or spriteConfig.getParent == nil then
        return nil
    end

    return spriteConfig:getParent()
end

local function getEntityId(gameScript)
    if gameScript == nil then
        return nil
    end

    if gameScript.getFullName ~= nil then
        local fullName = gameScript:getFullName()
        if type(fullName) == "string" and fullName ~= "" then
            return fullName
        end
    end

    if gameScript.getName ~= nil then
        local name = gameScript:getName()
        if type(name) == "string" and name ~= "" then
            return "Base." .. name
        end
    end

    return nil
end

local function getDefinition(objectInfo)
    local gameScript = getGameScript(objectInfo)
    if gameScript == nil then
        return nil
    end

    local entityId = getEntityId(gameScript)
    if entityId ~= nil then
        local definition = DefinitionLookup.getEffectiveDefinitionByEntity(entityId)
        if definition ~= nil then
            return definition
        end
    end

    local largeGateProfile = LargeGateBuildProfile.getByGameScript(gameScript)
    return largeGateProfile and largeGateProfile.definition or nil
end

local function applyFrameRequirement(buildObject, objectInfo)
    if buildObject == nil then
        return
    end

    local definition = getDefinition(objectInfo)
    if definition == nil then
        return
    end

    local frameRequirement = DoorTypes.getFrameRequirement(definition.doorType)
    if frameRequirement == nil then
        return
    end

    buildObject.dontNeedFrame = frameRequirement == "none"
end

if not ISBuildIsoEntity._lmionV3DoorFrameRequirementInstalled then
    ISBuildIsoEntity._lmionV3DoorFrameRequirementInstalled = true

    local previousNew = ISBuildIsoEntity.new

    ISBuildIsoEntity.new = function(self, character, objectInfo, ...)
        local buildObject = previousNew(self, character, objectInfo, ...)
        applyFrameRequirement(buildObject, objectInfo)
        return buildObject
    end

    print("[LMION:DEV] definition-owned Build frame requirement hook installed")
end
