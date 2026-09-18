local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"

local GarageCraftRecipeHydrator = {}

local function fail(message)
    error("LMION GarageCraftRecipeHydrator: " .. message, 3)
end

local function getSingleSkill(skill)
    if type(skill) ~= "table" then
        fail("construction.skill must be a table")
    end

    local skillName = nil
    local skillLevel = nil

    for name, level in pairs(skill) do
        if skillName ~= nil then
            fail("garage construction currently supports one construction skill")
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

local function getMinimumRequirements(definition)
    return GarageRequirements.getRequirements(
        { definition = definition },
        GarageBuild.MinWidth
    )
end

local function buildRecipeScript(definition)
    local construction = definition.construction
    if type(construction) ~= "table" then
        fail("definition has no construction contract")
    end

    local skillName, skillLevel = getSingleSkill(construction.skill)
    if skillName ~= "MetalWelding" then
        fail("unsupported garage construction skill " .. tostring(skillName))
    end

    local requirements = getMinimumRequirements(definition)
    if requirements == nil then
        fail("could not derive minimum-width garage requirements")
    end

    local lines = {
        "CraftRecipe",
        "{",
    }

    addValue(lines, "timedAction", "BuildWallMetal")
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
    lines[#lines + 1] = "        item 1 tags[base:weldingmask] mode:keep,"
    lines[#lines + 1] = "        item 1 [Base.BlowTorch] flags[DontRecordInput],"
    lines[#lines + 1] = string.format(
        "        item %d [Base.SmallSheetMetal],",
        requirements.SmallSheetMetal.amount
    )

    if requirements.GlassPanel ~= nil then
        lines[#lines + 1] = string.format(
            "        item %d [Base.GlassPanel],",
            requirements.GlassPanel.amount
        )
    end

    lines[#lines + 1] = string.format(
        "        item variable[%d:2147483647] [Base.MetalBar;Base.IronBar],",
        requirements.Bars.amount
    )
    lines[#lines + 1] = string.format(
        "        item %d [Base.Hinge],",
        requirements.Hinge.amount
    )
    lines[#lines + 1] = string.format(
        "        item %d [Base.WeldingRods] flags[DontRecordInput],",
        requirements.WeldingRods.amount
    )
    lines[#lines + 1] = "    }"
    lines[#lines + 1] = "}"

    return table.concat(lines, "\n")
end

function GarageCraftRecipeHydrator.hydrateDefinition(definitionId)
    local definition = Resolver.resolveDefinition(definitionId)
    local recipe = BuildRecipe.getByEntityId(definition.entity)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(definition.entity))
    end

    recipe:Load(recipe:getName(), buildRecipeScript(definition))
    recipe:OnScriptsLoaded(nil)

    return recipe
end

return GarageCraftRecipeHydrator
