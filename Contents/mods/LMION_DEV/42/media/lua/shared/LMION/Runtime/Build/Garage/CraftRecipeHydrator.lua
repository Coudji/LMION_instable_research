local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeInputs = require "LMION/Runtime/Build/CraftRecipeInputs"
local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageMaterials = require "LMION/Services/Build/Garage/Materials"

local GarageCraftRecipeHydrator = {}

local function fail(message)
    error("LMION GarageCraftRecipeHydrator: " .. message, 3)
end

local function addValue(lines, key, value)
    if value ~= nil then
        lines[#lines + 1] = string.format("    %s = %s,", key, tostring(value))
    end
end

local function getSingleSkill(skill)
    if type(skill) ~= "table" then
        fail("construction.skill must be a table")
    end

    local name, level = nil, nil
    for skillName, skillLevel in pairs(skill) do
        if name ~= nil then
            fail("Garage Build currently supports one governing construction skill")
        end
        name = skillName
        level = tonumber(skillLevel)
    end

    if type(name) ~= "string" or name == "" or level == nil then
        fail("construction.skill must contain one valid skill")
    end

    return name, math.floor(level)
end

local function buildRecipeScript(definition)
    local construction = definition.construction
    if type(construction) ~= "table" then
        fail("definition has no construction contract")
    end

    local timedAction = construction.timedAction
    if type(timedAction) ~= "string" or timedAction == "" then
        fail("construction.timedAction must be a non-empty string")
    end

    local skillName, skillLevel = getSingleSkill(construction.skill)
    local materials = GarageMaterials.getRecipeMaterials(definition, GarageBuild.MinWidth)
    if materials == nil then
        fail("could not derive minimum-width garage materials")
    end

    local lines = { "CraftRecipe", "{" }
    addValue(lines, "timedAction", timedAction)
    addValue(lines, "time", construction.time)
    addValue(lines, "category", construction.category)
    addValue(lines, "SkillRequired", skillName .. ":" .. tostring(skillLevel))

    if construction.xp ~= nil then
        addValue(lines, "xpAward", skillName .. ":" .. tostring(construction.xp))
    end
    if type(construction.variantGroup) == "string" and construction.variantGroup ~= "" then
        addValue(lines, "OnAddToMenu", "LMIONBuildVariantOnAddToMenu")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "    inputs"
    lines[#lines + 1] = "    {"
    CraftRecipeInputs.addTools(lines, construction.tools)
    CraftRecipeInputs.addMaterials(lines, materials)
    lines[#lines + 1] = "    }"
    lines[#lines + 1] = "}"

    return table.concat(lines, "\n")
end

function GarageCraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
    local definition = Resolver.resolveDefinition(definitionId)
    entityId = entityId or definition.entity
    local recipe = BuildRecipe.getByEntityId(entityId)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(entityId))
    end

    return BuildRecipe.reload(recipe, buildRecipeScript(definition))
end

return GarageCraftRecipeHydrator
