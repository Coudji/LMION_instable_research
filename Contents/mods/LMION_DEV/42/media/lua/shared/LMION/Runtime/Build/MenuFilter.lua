local BuildRecipe = require "LMION/PZ/BuildRecipe"
local EntityIndex = require "LMION/Definitions/EntityIndex"
local Resolver = require "LMION/Definitions/Resolver"
local LargeGateBuildProfile = require "LMION/Services/Build/LargeGate/Profile"
local Unlock = require "LMION/Services/Build/Unlock"
local VariantGroups = require "LMION/Services/Build/VariantGroups"

local MenuFilter = {}
local installed = false

local function getDefinition(recipe)
    local entityId = BuildRecipe.getEntityId(recipe)
    if entityId == nil then
        return nil
    end

    local definitionId = EntityIndex.getDefinitionId(entityId)
    if definitionId ~= nil then
        return Resolver.resolveDefinition(definitionId)
    end

    local largeGateProfile = LargeGateBuildProfile.getByEntityId(entityId)
    return largeGateProfile and largeGateProfile.definition or nil
end

local function shouldShow(params)
    if params ~= nil and params.shouldShowAll then
        return true
    end

    local recipe = params and params.recipe or nil
    local player = params and params.player or nil

    local group = VariantGroups.getForRecipe(recipe)
    if group ~= nil then
        return VariantGroups.shouldShowRecipe(recipe, player)
    end

    local definition = getDefinition(recipe)
    if definition == nil then
        return true
    end

    return Unlock.shouldShow(definition, player)
end

function MenuFilter.install()
    if installed then
        return false
    end

    installed = true

    function LMIONBuildOnAddToMenu(params)
        return shouldShow(params)
    end

    function LMIONBuildVariantOnAddToMenu(params)
        return shouldShow(params)
    end

    return true
end

return MenuFilter
