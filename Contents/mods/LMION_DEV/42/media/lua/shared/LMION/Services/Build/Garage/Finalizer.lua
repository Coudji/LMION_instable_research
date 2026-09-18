local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageMaterials = require "LMION/Services/Build/Garage/Materials"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"
local SingleTileDoorFinalizer = require "LMION/Services/Build/SingleTileDoor/Finalizer"

local GarageFinalizer = {}

local function getContainers(buildObject)
    local logic = buildObject and buildObject.buildPanelLogic or nil
    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end

    return buildObject and buildObject.containers or nil
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

local function getVanillaWidthInputCount(buildObject, profile)
    local data = buildObject and buildObject.modData or nil
    local definition = profile and profile.definition or nil
    local requirement = definition and GarageMaterials.getWidthInputRequirement(
        definition,
        GarageBuild.MinWidth
    ) or nil

    if data == nil or requirement == nil then
        return 0
    end

    local count = 0
    for index = 1, #requirement.itemTypes do
        count = count
            + (tonumber(data["need:" .. requirement.itemTypes[index]]) or 0)
    end

    return count
end

function GarageFinalizer.getProfile(buildObject)
    return buildObject
        and buildObject.objectInfo
        and GarageBuild.getProfileFromObjectInfo(buildObject.objectInfo)
        or nil
end

function GarageFinalizer.beforeSetInfo(buildObject, profile)
    if profile == nil
        or buildObject.character:isBuildCheat()
        or buildObject._lmionGarageExtrasConsumed then
        return true
    end

    if not GarageRequirements.consumeExtras(
        buildObject.character,
        profile,
        getWidth(buildObject),
        getContainers(buildObject),
        getVanillaWidthInputCount(buildObject, profile)
    ) then
        return false
    end

    GarageRequirements.recordExtras(buildObject)
    buildObject._lmionGarageExtrasConsumed = true
    return true
end

function GarageFinalizer.finalize(buildObject, square, profile)
    if profile == nil then
        return nil
    end

    return SingleTileDoorFinalizer.finalize(
        square,
        profile,
        buildObject.craftRecipe,
        buildObject.character
    )
end

return GarageFinalizer
