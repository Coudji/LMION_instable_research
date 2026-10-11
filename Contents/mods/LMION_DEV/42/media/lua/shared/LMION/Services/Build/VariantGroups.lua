local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local DefinitionMembers = require "LMION/Services/Build/DefinitionMembers"
local Unlock = require "LMION/Services/Build/Unlock"
local VariantAvailability = require "LMION/Services/Build/VariantAvailability"

local VariantGroups = {}

local cachedRevision = -1
local groupsByKey = {}
local groupsByLogicalId = {}
local groupsByDefinitionId = {}
local memberByEntityId = {}
local memberByRecipeName = {}

local function getEntityShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function makeGroupKey(groupId, role)
    return groupId .. "\31" .. tostring(role or "")
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

local function addDefinitionGroup(definitionId, group)
    local groups = groupsByDefinitionId[definitionId]
    if groups == nil then
        groups = {}
        groupsByDefinitionId[definitionId] = groups
    end

    for index = 1, #groups do
        if groups[index] == group then
            return
        end
    end

    groups[#groups + 1] = group
end

local function getOrCreateGroup(groupId, role)
    local key = makeGroupKey(groupId, role)
    local group = groupsByKey[key]
    if group ~= nil then
        return group
    end

    group = {
        key = key,
        id = groupId,
        role = role,
        members = {},
        memberByDefinitionId = {},
    }
    groupsByKey[key] = group

    local logicalGroups = groupsByLogicalId[groupId]
    if logicalGroups == nil then
        logicalGroups = {}
        groupsByLogicalId[groupId] = logicalGroups
    end
    logicalGroups[#logicalGroups + 1] = group

    return group
end

local function finalizeGroups()
    for _, group in pairs(groupsByKey) do
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

local function addMember(definitionId, definition, groupId, buildMember)
    local entityId = buildMember.entityId
    local role = buildMember.role
    local recipeName = getEntityShortName(entityId)
    local group = getOrCreateGroup(groupId, role)
    local progressionLevel = Unlock.getProgressionLevel(definition)

    local member = {
        definitionId = definitionId,
        entityId = entityId,
        recipeName = recipeName,
        role = role,
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
        group = group,
    }

    group.members[#group.members + 1] = member
    group.memberByDefinitionId[definitionId] = member
    addDefinitionGroup(definitionId, group)
    memberByEntityId[entityId] = member

    if memberByRecipeName[recipeName] == nil then
        memberByRecipeName[recipeName] = member
    else
        memberByRecipeName[recipeName] = false
    end
end

local function rebuild()
    local revision = Registry.getRevision()
    if cachedRevision == revision then
        return
    end

    groupsByKey = {}
    groupsByLogicalId = {}
    groupsByDefinitionId = {}
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

        if type(groupId) == "string" and groupId ~= "" then
            local buildMembers = DefinitionMembers.get(definition)
            for memberIndex = 1, #buildMembers do
                addMember(
                    definitionId,
                    definition,
                    groupId,
                    buildMembers[memberIndex]
                )
            end
        end
    end

    finalizeGroups()
    cachedRevision = revision
end

function VariantGroups.getById(groupId, role)
    rebuild()

    if role ~= nil then
        return groupsByKey[makeGroupKey(groupId, role)]
    end

    local groups = groupsByLogicalId[groupId]
    if groups ~= nil and #groups == 1 then
        return groups[1]
    end

    return nil
end

function VariantGroups.getForDefinition(definitionId, role)
    rebuild()

    local groups = groupsByDefinitionId[definitionId]
    if groups == nil then
        return nil
    end

    if role ~= nil then
        for index = 1, #groups do
            if groups[index].role == role then
                return groups[index]
            end
        end
        return nil
    end

    if #groups == 1 then
        return groups[1]
    end

    return nil
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
    return member and member.group or nil
end

function VariantGroups.shouldShowRecipe(recipe, player)
    local member = VariantGroups.getMemberForRecipe(recipe)
    local group = member and member.group or nil

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
