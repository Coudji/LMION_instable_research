local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeScript = require "LMION/Runtime/Build/CraftRecipeScript"

local LargeGateCraftRecipeHydrator = {}

local function fail(message)
    error("LMION LargeGateCraftRecipeHydrator: " .. message, 3)
end

local function splitNumber(value, label)
    if value == nil then
        return nil
    end

    local number = tonumber(value)
    if number == nil or number < 0 then
        fail(label .. " must be a non-negative number")
    end

    local half = number / 2
    if half ~= math.floor(half) then
        fail(label .. " must split evenly across LargeGate leaves A and B")
    end

    return half
end

local function splitXp(xp)
    if xp == nil then
        return nil
    end

    if type(xp) ~= "table" then
        return splitNumber(xp, "construction.xp")
    end

    local result = {}
    for skillName, amount in pairs(xp) do
        result[skillName] = splitNumber(
            amount,
            "construction.xp." .. tostring(skillName)
        )
    end
    return result
end

local function splitMaterials(materials)
    if materials == nil then
        return nil
    end
    if type(materials) ~= "table" then
        fail("construction.materials must be a table")
    end

    local result = {}
    for index = 1, #materials do
        local source = materials[index]
        if type(source) ~= "table" then
            fail("construction material at index " .. tostring(index) .. " must be a table")
        end

        local material = {}
        for key, value in pairs(source) do
            material[key] = value
        end

        if source.amount ~= nil then
            if type(source.amount) ~= "number" then
                fail("LargeGate material amount at index " .. tostring(index) .. " must be numeric")
            end
            material.amount = splitNumber(
                source.amount,
                "construction.materials[" .. tostring(index) .. "].amount"
            )
        end

        if source.uses ~= nil then
            if type(source.uses) ~= "number" then
                fail("LargeGate material uses at index " .. tostring(index) .. " must be numeric")
            end
            material.uses = splitNumber(
                source.uses,
                "construction.materials[" .. tostring(index) .. "].uses"
            )
        end

        result[index] = material
    end

    return result
end

local function projectLeafConstruction(definition)
    local construction = definition.construction
    if type(construction) ~= "table" then
        fail("definition has no construction contract")
    end

    local projected = {}
    for key, value in pairs(construction) do
        projected[key] = value
    end

    projected.time = splitNumber(construction.time, "construction.time")
    projected.xp = splitXp(construction.xp)
    projected.materials = splitMaterials(construction.materials)

    return projected
end

function LargeGateCraftRecipeHydrator.hydrateDefinition(
    definitionId,
    entityId
)
    local definition = Resolver.resolveDefinition(definitionId)
    local recipe = BuildRecipe.getByEntityId(entityId)

    if recipe == nil then
        fail("buildable leaf recipe not found for " .. tostring(entityId))
    end

    return BuildRecipe.reload(
        recipe,
        CraftRecipeScript.build(projectLeafConstruction(definition))
    )
end

return LargeGateCraftRecipeHydrator
