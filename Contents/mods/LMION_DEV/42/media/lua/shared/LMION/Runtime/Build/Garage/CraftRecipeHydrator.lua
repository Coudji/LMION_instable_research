local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeScript = require "LMION/Runtime/Build/CraftRecipeScript"
local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageMaterials = require "LMION/Services/Build/Garage/Materials"

local GarageCraftRecipeHydrator = {}

local function fail(message)
    error("LMION GarageCraftRecipeHydrator: " .. message, 3)
end

local function validateSingleSkill(skill)
    if type(skill) ~= "table" then
        fail("construction.skill must be a table")
    end

    local count = 0
    for skillName, skillLevel in pairs(skill) do
        count = count + 1
        if type(skillName) ~= "string"
            or skillName == ""
            or tonumber(skillLevel) == nil then
            fail("construction.skill must contain one valid skill")
        end
    end

    if count ~= 1 then
        fail("Garage Build currently supports one governing construction skill")
    end
end

local function projectConstruction(definition)
    local construction = definition.construction
    if type(construction) ~= "table" then
        fail("definition has no construction contract")
    end

    validateSingleSkill(construction.skill)

    local materials = GarageMaterials.getRecipeMaterials(
        definition,
        GarageBuild.MinWidth
    )
    if materials == nil then
        fail("could not derive minimum-width garage materials")
    end

    local projected = {}
    for key, value in pairs(construction) do
        projected[key] = value
    end
    projected.materials = materials

    return projected
end

function GarageCraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
    local definition = Resolver.resolveDefinition(definitionId)
    entityId = entityId or definition.entity
    local recipe = BuildRecipe.getByEntityId(entityId)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(entityId))
    end

    return BuildRecipe.reload(
        recipe,
        CraftRecipeScript.build(projectConstruction(definition))
    )
end

return GarageCraftRecipeHydrator
