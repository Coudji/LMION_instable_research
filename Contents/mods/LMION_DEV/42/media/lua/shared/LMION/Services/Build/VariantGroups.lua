local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"

local VariantGroups = {}

local cachedRevision = -1
local groupsById = {}
local groupByDefinitionId = {}
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
            local recipeName = getEntityShortName(definition.entity)
            if recipeName ~= nil then
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
                    entityId = definition.entity,
                    recipeName = recipeName,
                    index = #group.members + 1,
                }

                group.members[#group.members + 1] = member
                group.memberByDefinitionId[definitionId] = member
                groupByDefinitionId[definitionId] = group
                memberByRecipeName[recipeName] = member

                if group.representative == nil then
                    group.representative = member
                end
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

function VariantGroups.getMemberForRecipeName(recipeName)
    if type(recipeName) ~= "string" or recipeName == "" then
        return nil
    end

    rebuild()
    return memberByRecipeName[recipeName]
end

function VariantGroups.getForRecipeName(recipeName)
    local member = VariantGroups.getMemberForRecipeName(recipeName)
    if member == nil then
        return nil
    end

    return groupByDefinitionId[member.definitionId]
end

function VariantGroups.shouldShowRecipeName(recipeName)
    local group = VariantGroups.getForRecipeName(recipeName)
    if group == nil or group.representative == nil then
        return true
    end

    return recipeName == group.representative.recipeName
end

return VariantGroups
