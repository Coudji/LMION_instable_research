local Resolver = require "LMION/Definitions/Resolver"
require "LMION/Services/Build/VariantGroups"

local CraftRecipeHydrator = {}

local TOOL_INPUTS = {
    ["base:screwdriver"] = "item 1 [Base.Screwdriver] mode:keep",
    ["base:hammer"] = "item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight]",
}

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
            fail("recipe hydration prototype currently supports one construction skill")
        end

        skillName = name
        skillLevel = tonumber(level)
    end

    if skillName == nil or skillLevel == nil then
        fail("construction.skill must contain one valid skill")
    end

    return skillName, math.floor(skillLevel)
end

local function getEntityShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        fail("definition has no valid entity")
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function addValue(lines, key, value)
    if value == nil then
        return
    end

    lines[#lines + 1] = string.format("    %s = %s,", key, tostring(value))
end

local function addTools(lines, tools)
    if tools == nil then
        return
    end

    if type(tools) ~= "table" then
        fail("construction.tools must be a table")
    end

    for index = 1, #tools do
        local tool = tools[index]
        local line = type(tool) == "table" and TOOL_INPUTS[tool.tag] or nil

        if line == nil then
            fail("unsupported construction tool at index " .. tostring(index))
        end

        lines[#lines + 1] = "        " .. line .. ","
    end
end

local function addMaterials(lines, materials)
    if materials == nil then
        return
    end

    if type(materials) ~= "table" then
        fail("construction.materials must be a table")
    end

    for index = 1, #materials do
        local material = materials[index]
        local item = type(material) == "table" and material.item or nil
        local amount = type(material) == "table" and tonumber(material.amount) or nil

        if type(item) ~= "string" or item == "" or amount == nil then
            fail("invalid construction material at index " .. tostring(index))
        end

        lines[#lines + 1] = string.format(
            "        item %d [%s],",
            math.floor(amount),
            item
        )
    end
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
    addTools(lines, construction.tools)
    addMaterials(lines, construction.materials)
    lines[#lines + 1] = "    }"
    lines[#lines + 1] = "}"

    return table.concat(lines, "\n")
end

function CraftRecipeHydrator.hydrateDefinition(definitionId)
    local definition = Resolver.resolveDefinition(definitionId)
    local recipeName = getEntityShortName(definition.entity)

    if ScriptManager == nil or ScriptManager.instance == nil then
        fail("ScriptManager is unavailable")
    end

    local recipe = ScriptManager.instance:getBuildableRecipe(recipeName)
    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(definition.entity))
    end

    local recipeScript = buildRecipeScript(definition)
    recipe:Load(recipe:getName(), recipeScript)

    -- The empty entity CraftRecipe has already passed the engine's first
    -- OnScriptsLoaded phase. Re-run it after hydrating the actual inputs and
    -- timed action so PZ can resolve its derived recipe state.
    recipe:OnScriptsLoaded(nil)

    print(string.format(
        "[LMION:DEV] hydrated build recipe %s from %s (category=%s, inputs=%d)",
        tostring(recipe:getName()),
        tostring(definitionId),
        tostring(recipe:getCategory()),
        recipe:getInputCount()
    ))

    return recipe
end

return CraftRecipeHydrator
