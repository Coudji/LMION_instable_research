local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"
local GarageLengthState = require "LMION/Services/Build/Garage/LengthState"
local SingleTileDoorFinalizer = require "LMION/Services/Build/SingleTileDoor/Finalizer"

local GarageFinalizer = {}

local function getContainers(buildObject)
    local logic = buildObject and buildObject.buildPanelLogic or nil
    if logic ~= nil and logic.getContainers ~= nil then
        return logic:getContainers()
    end

    return buildObject and buildObject.containers or nil
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

local function getVanillaBarCount(buildObject)
    local data = buildObject and buildObject.modData or nil
    return (tonumber(data and data["need:Base.MetalBar"]) or 0)
        + (tonumber(data and data["need:Base.IronBar"]) or 0)
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
        getLength(buildObject),
        getContainers(buildObject),
        getVanillaBarCount(buildObject)
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
