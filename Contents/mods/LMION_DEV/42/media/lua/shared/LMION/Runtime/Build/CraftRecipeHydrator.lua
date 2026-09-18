local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeInputs = require "LMION/Runtime/Build/CraftRecipeInputs"

local CraftRecipeHydrator = {}

local function fail(message)
    error("LMION CraftRecipeHydrator: " .. message, 3)
end

local function addValue(lines, key, value)
    if value == nil then
        return
    end

    lines[#lines + 1] = string.format("    %s = %s,", key, tostring(value))
end

local function serializeLevels(levels, label)
    if levels == nil then
        return nil, {}
    end
    if type(levels) ~= "table" then
        fail(label .. " must be a table")
    end

    local names = {}
    for name in pairs(levels) do
        if type(name) ~= "string" or name == "" then
            fail(label .. " contains an invalid skill name")
        end
        names[#names + 1] = name
    end
    table.sort(names)

    local values = {}
    for index = 1, #names do
        local name = names[index]
        local level = tonumber(levels[name])
        if level == nil or level < 0 or level ~= math.floor(level) then
            fail(label .. " contains an invalid level for " .. name)
        end
        values[index] = name .. ":" .. tostring(level)
    end

    return #values > 0 and table.concat(values, ";") or nil, names
end

local function serializeXp(xp, skillNames)
    if xp == nil then
        return nil
    end

    if type(xp) == "table" then
        return serializeLevels(xp, "construction.xp")
    end

    local amount = tonumber(xp)
    if amount == nil or amount < 0 then
        fail("construction.xp must be a non-negative number or a skill table")
    end
    if #skillNames ~= 1 then
        fail("numeric construction.xp requires exactly one construction skill")
    end

    return skillNames[1] .. ":" .. tostring(amount)
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

    local skillRequired, skillNames = serializeLevels(
        construction.skill,
        "construction.skill"
    )
    local xpAward = serializeXp(construction.xp, skillNames)

    local lines = {
        "CraftRecipe",
        "{",
    }

    addValue(lines, "timedAction", timedAction)
    addValue(lines, "time", construction.time)
    addValue(lines, "category", construction.category)
    addValue(lines, "SkillRequired", skillRequired)
    addValue(lines, "xpAward", xpAward)

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

function CraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
    local definition = Resolver.resolveDefinition(definitionId)
    entityId = entityId or definition.entity
    local recipe = BuildRecipe.getByEntityId(entityId)

    if recipe == nil then
        fail("buildable recipe not found for " .. tostring(entityId))
    end

    recipe:Load(recipe:getName(), buildRecipeScript(definition))
    recipe:OnScriptsLoaded(nil)

    return recipe
end

return CraftRecipeHydrator
