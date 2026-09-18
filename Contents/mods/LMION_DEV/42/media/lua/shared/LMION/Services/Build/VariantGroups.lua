local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"

local VariantGroups = {}

local cachedRevision = -1
local groupsById = {}
local groupByDefinitionId = {}
local memberByEntityId = {}
local memberByRecipeName = {}

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
    memberByEntityId = {}
    memberByRecipeName = {}

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
        local entityId = type(definition) == "table"
            and definition.entity
            or nil

        if type(groupId) == "string"
            and groupId ~= ""
            and type(entityId) == "string"
            and entityId ~= "" then
            local recipeName = getEntityShortName(entityId)
            local group = groupsById[groupId]

            if group == nil then
                group = {
                    id = groupId,
                    members = {},
                    memberByDefinitionId = {},
                }
                groupsById[groupId] = group
            end

            local member = {
                definitionId = definitionId,
                entityId = entityId,
                recipeName = recipeName,
                index = #group.members + 1,
            }

            group.members[#group.members + 1] = member
            group.memberByDefinitionId[definitionId] = member
            groupByDefinitionId[definitionId] = group
            memberByEntityId[entityId] = member

            -- Kept only as a compatibility fallback for PZ lifecycle points
            -- where recipe -> parent GameEntity cannot be resolved yet.
            if memberByRecipeName[recipeName] == nil then
                memberByRecipeName[recipeName] = member
            else
                memberByRecipeName[recipeName] = false
            end

            if group.representative == nil then
                group.representative = member
            end
        end
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

function VariantGroups.getMemberForEntityId(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    rebuild()
    return memberByEntityId[entityId]
end

function VariantGroups.getMemberForRecipe(recipe)
    local entityId = BuildRecipe.getEntityId(recipe)
    if entityId ~= nil then
        return VariantGroups.getMemberForEntityId(entityId)
    end

    local recipeName = recipe and recipe.getName and recipe:getName() or nil
    if type(recipeName) ~= "string" or recipeName == "" then
        return nil
    end

    rebuild()
    local member = memberByRecipeName[recipeName]
    return member ~= false and member or nil
end

function VariantGroups.getForRecipe(recipe)
    local member = VariantGroups.getMemberForRecipe(recipe)
    return member and groupByDefinitionId[member.definitionId] or nil
end

function VariantGroups.shouldShowRecipe(recipe)
    local group = VariantGroups.getForRecipe(recipe)
    local member = VariantGroups.getMemberForRecipe(recipe)

    if group == nil or group.representative == nil or member == nil then
        return true
    end

    return member.entityId == group.representative.entityId
end

return VariantGroups
