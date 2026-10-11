local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeScript = require "LMION/Runtime/Build/CraftRecipeScript"

local CraftRecipeHydrator = {}

local function fail(message)
    error("LMION CraftRecipeHydrator: " .. message, 3)
end

function CraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
    local definition = Resolver.resolveDefinition(definitionId)
    entityId = entityId or definition.entity
    local recipe = BuildRecipe.getByEntityId(entityId)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(entityId))
    end

    return BuildRecipe.reload(
        recipe,
        CraftRecipeScript.build(definition.construction)
    )
end

return CraftRecipeHydrator
