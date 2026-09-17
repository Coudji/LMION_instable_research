local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"

local VariantGroups = {}

local cachedRevision = -1
local groupsById = {}
local groupByDefinitionId = {}
local definitionIdByRecipeName = {}

local function getEntityShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function rebuild()
    local revision = Registry.getRevision()
    if cachedRevision == revision then
        return
    end

    groupsById = {}
    groupByDefinitionId = {}
    definitionIdByRecipeName = {}

    local definitionIds = Registry.getDefinitionIds()
    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)
        local construction = type(definition) == "table"
            and definition.construction
            or nil
        local groupId = type(construction) == "table"
            and construction.variantGroup
            or nil

        if type(groupId) == "string" and groupId ~= "" then
            local recipeName = getEntityShortName(definition.entity)
            if recipeName ~= nil then
                local group = groupsById[groupId]
                if group == nil then
                    group = {
                        id = groupId,
                        members = {},
                    }
                    groupsById[groupId] = group
                end

                local member = {
                    definitionId = definitionId,
                    entityId = definition.entity,
                    recipeName = recipeName,
                }

                group.members[#group.members + 1] = member
                groupByDefinitionId[definitionId] = group
                definitionIdByRecipeName[recipeName] = definitionId
            end
        end
    end

    for _, group in pairs(groupsById) do
        table.sort(group.members, function(a, b)
            return a.definitionId < b.definitionId
        end)

        group.memberByDefinitionId = {}
        for index = 1, #group.members do
            local member = group.members[index]
            member.index = index
            group.memberByDefinitionId[member.definitionId] = member
        end

        group.representative = group.members[1]
    end

    cachedRevision = revision
end

function VariantGroups.getById(groupId)
    rebuild()
    return groupsById[groupId]
end

function VariantGroups.getForDefinition(definitionId)
    rebuild()
    return groupByDefinitionId[definitionId]
end

function VariantGroups.getForRecipe(recipe)
    if recipe == nil or recipe.getName == nil then
        return nil
    end

    rebuild()

    local definitionId = definitionIdByRecipeName[recipe:getName()]
    if definitionId == nil then
        return nil
    end

    return groupByDefinitionId[definitionId]
end

function VariantGroups.getDefinitionIdForRecipe(recipe)
    if recipe == nil or recipe.getName == nil then
        return nil
    end

    rebuild()
    return definitionIdByRecipeName[recipe:getName()]
end

function VariantGroups.getRecipeForMember(member)
    if type(member) ~= "table"
        or type(member.recipeName) ~= "string"
        or ScriptManager == nil
        or ScriptManager.instance == nil then
        return nil
    end

    return ScriptManager.instance:getBuildableRecipe(member.recipeName)
end

function VariantGroups.shouldShowRecipe(recipe)
    local group = VariantGroups.getForRecipe(recipe)
    if group == nil or group.representative == nil then
        return true
    end

    return recipe:getName() == group.representative.recipeName
end

-- PZ's Build/Craft recipe lists already support OnAddToMenu callbacks in both
-- list and grid modes. Hydrated grouped recipes point at this callback so only
-- the representative recipe is shown; every underlying recipe still exists.
function LMIONBuildVariantOnAddToMenu(params)
    return VariantGroups.shouldShowRecipe(params and params.recipe or nil)
end

return VariantGroups
