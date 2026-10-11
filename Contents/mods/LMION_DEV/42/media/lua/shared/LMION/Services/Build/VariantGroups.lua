local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local Unlock = require "LMION/Services/Build/Unlock"
local VariantAvailability = require "LMION/Services/Build/VariantAvailability"

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

local function getDurabilityAtLevel(definition, level)
    local durability = type(definition) == "table"
        and definition.durability
        or nil

    if type(durability) ~= "table" then
        return -1
    end

    local health = tonumber(durability.health)
    if health == nil then
        return -1
    end

    local skillBaseHealth = tonumber(durability.skillBaseHealth) or 0
    return health + skillBaseHealth * (tonumber(level) or 0)
end

local function getSortName(definitionId, definition, entityId)
    local value = type(definition) == "table"
        and definition.displayName
        or nil

    if type(value) ~= "string" or value == "" then
        value = entityId or definitionId
    end

    return string.lower(tostring(value))
end

local function finalizeGroups()
    for _, group in pairs(groupsById) do
        table.sort(group.members, function(a, b)
            if a.progressionLevel ~= b.progressionLevel then
                return a.progressionLevel < b.progressionLevel
            end
            if a.durabilityScore ~= b.durabilityScore then
                return a.durabilityScore < b.durabilityScore
            end
            if a.sortName ~= b.sortName then
                return a.sortName < b.sortName
            end
            return a.definitionId < b.definitionId
        end)

        for index = 1, #group.members do
            group.members[index].index = index
        end

        group.representative = group.members[1]
    end
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

            local progressionLevel = Unlock.getProgressionLevel(definition)
            local member = {
                definitionId = definitionId,
                entityId = entityId,
                recipeName = recipeName,
                progressionLevel = progressionLevel,
                durabilityScore = getDurabilityAtLevel(
                    definition,
                    progressionLevel
                ),
                sortName = getSortName(
                    definitionId,
                    definition,
                    entityId
                ),
            }

            group.members[#group.members + 1] = member
            group.memberByDefinitionId[definitionId] = member
            groupByDefinitionId[definitionId] = group
            memberByEntityId[entityId] = member

            if memberByRecipeName[recipeName] == nil then
                memberByRecipeName[recipeName] = member
            else
                memberByRecipeName[recipeName] = false
            end
        end
    end

    finalizeGroups()
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

function VariantGroups.shouldShowRecipe(recipe, player)
    local group = VariantGroups.getForRecipe(recipe)
    local member = VariantGroups.getMemberForRecipe(recipe)

    if group == nil or member == nil then
        return true
    end

    local representative = VariantAvailability.getRepresentative(group, player)
    if representative == nil then
        return false
    end

    return member.entityId == representative.entityId
end

return VariantGroups
