local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeInputs = require "LMION/Runtime/Build/CraftRecipeInputs"

local CraftRecipeHydrator = {}

local TIMED_ACTIONS = {
    Woodwork = "BuildWallHammer",
    MetalWelding = "BuildWallMetal",
}

local function fail(message)
    error("LMION CraftRecipeHydrator: " .. message, 3)
end

local function getSingleSkill(skill)
    if type(skill) ~= "table" then
        fail("construction.skill must be a table")
    end

    local skillName = nil
    local skillLevel = nil

    for name, level in pairs(skill) do
        if skillName ~= nil then
            fail("recipe hydration currently supports one construction skill")
        end

        skillName = name
        skillLevel = tonumber(level)
    end

    if skillName == nil or skillLevel == nil then
        fail("construction.skill must contain one valid skill")
    end

    return skillName, math.floor(skillLevel)
end

local function addValue(lines, key, value)
    if value == nil then
        return
    end

    lines[#lines + 1] = string.format("    %s = %s,", key, tostring(value))
end

local function buildRecipeScript(definition)
    local construction = definition.construction
    if type(construction) ~= "table" then
        fail("definition has no construction contract")
    end

    local skillName, skillLevel = getSingleSkill(construction.skill)
    local timedAction = TIMED_ACTIONS[skillName]
    if timedAction == nil then
        fail("unsupported construction skill " .. tostring(skillName))
    end

    local lines = {
        "CraftRecipe",
        "{",
    }

    addValue(lines, "timedAction", timedAction)
    addValue(lines, "time", construction.time)
    addValue(lines, "category", construction.category)
    addValue(lines, "SkillRequired", skillName .. ":" .. tostring(skillLevel))

    if construction.xp ~= nil then
        addValue(lines, "xpAward", skillName .. ":" .. tostring(construction.xp))
    end

    if type(construction.variantGroup) == "string"
        and construction.variantGroup ~= "" then
        addValue(lines, "OnAddToMenu", "LMIONBuildVariantOnAddToMenu")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "    inputs"
    lines[#lines + 1] = "    {"
    CraftRecipeInputs.addTools(lines, construction.tools)
    CraftRecipeInputs.addMaterials(lines, construction.materials)
    lines[#lines + 1] = "    }"
    lines[#lines + 1] = "}"

    return table.concat(lines, "\n")
end

function CraftRecipeHydrator.hydrateDefinition(definitionId)
    local definition = Resolver.resolveDefinition(definitionId)
    local recipe = BuildRecipe.getByEntityId(definition.entity)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(definition.entity))
    end

    recipe:Load(recipe:getName(), buildRecipeScript(definition))

    -- The entity CraftRecipe shell has already passed PZ's first script-load
    -- phase. Re-run it after loading definition-owned recipe data so derived
    -- recipe state is rebuilt by the engine.
    recipe:OnScriptsLoaded(nil)

    return recipe
end

return CraftRecipeHydrator
