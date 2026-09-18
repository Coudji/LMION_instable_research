local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeHydrator = require "LMION/Runtime/Build/CraftRecipeHydrator"
local GarageCraftRecipeHydrator = require "LMION/Runtime/Build/Garage/CraftRecipeHydrator"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"
local VariantMenuFilter = require "LMION/Runtime/Build/VariantMenuFilter"

local BuildBootstrap = {}
local hasRun = false

local function hydrateDefinition(definitionId, definition)
    if definition.doorType == "Garage" then
        GarageCraftRecipeHydrator.hydrateDefinition(definitionId)
        return
    end

    CraftRecipeHydrator.hydrateDefinition(definitionId)
end

local function hydrateDefinitionOwnedRecipes()
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)
        local construction = type(definition) == "table"
            and definition.construction
            or nil
        local entityId = type(definition) == "table"
            and definition.entity
            or nil

        if type(construction) == "table" and type(entityId) == "string" then
            local recipe = BuildRecipe.getByEntityId(entityId)

            if BuildRecipe.isEmptyShell(recipe) then
                hydrateDefinition(definitionId, definition)
            end
        end
    end
end

function BuildBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true

    VariantMenuFilter.install()
    VanillaLargeGateLeafPreparation.install()
    hydrateDefinitionOwnedRecipes()

    return true
end

return BuildBootstrap
