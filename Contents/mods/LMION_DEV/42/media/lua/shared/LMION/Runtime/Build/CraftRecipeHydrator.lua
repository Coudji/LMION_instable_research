local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"

local CraftRecipeHydrator = {}

local TOOL_INPUTS = {
    ["base:screwdriver"] = "item 1 [Base.Screwdriver] mode:keep",
    ["base:hammer"] = "item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight]",
    ["base:weldingmask"] = "item 1 [Base.WeldingMask] mode:keep",
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

local function getMaterialItems(material, index)
    local item = type(material) == "table" and material.item or nil
    if type(item) == "string" and item ~= "" then
        return item
    end

    local anyOf = type(material) == "table" and material.anyOf or nil
    if type(anyOf) ~= "table" or #anyOf == 0 then
        fail("invalid construction material at index " .. tostring(index))
    end

    local items = {}
    for itemIndex = 1, #anyOf do
        local candidate = anyOf[itemIndex]
        if type(candidate) ~= "string" or candidate == "" then
            fail("invalid construction material alternative at index " .. tostring(index))
        end
        items[#items + 1] = candidate
    end

    return table.concat(items, ";")
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
        local items = getMaterialItems(material, index)
        local amount = type(material) == "table" and tonumber(material.amount) or nil
        local uses = type(material) == "table" and tonumber(material.uses) or nil

        if (amount == nil) == (uses == nil) then
            fail("construction material must define exactly one of amount or uses at index " .. tostring(index))
        end

        local quantity = math.floor(amount or uses)
        if quantity < 1 then
            fail("construction material quantity must be positive at index " .. tostring(index))
        end

        local flags = uses ~= nil and " flags[DontRecordInput]" or ""
        lines[#lines + 1] = string.format(
            "        item %d [%s]%s,",
            quantity,
            items,
            flags
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
