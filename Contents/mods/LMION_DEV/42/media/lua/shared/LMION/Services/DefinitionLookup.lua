local EntityIndex = require "LMION/Definitions/EntityIndex"
local Resolver = require "LMION/Definitions/Resolver"
local WorldObjectIdentity = require "LMION/PZ/WorldObjectIdentity"

local DefinitionLookup = {}

function DefinitionLookup.getDefinitionIdByEntity(entityId)
    return EntityIndex.getDefinitionId(entityId)
end

function DefinitionLookup.getEffectiveDefinitionByEntity(entityId)
    local definitionId = EntityIndex.getDefinitionId(entityId)

    if definitionId == nil then
        return nil
    end

    return Resolver.resolveDefinition(definitionId)
end

function DefinitionLookup.getEntityIdForObject(object)
    return WorldObjectIdentity.getEntityId(object)
end

function DefinitionLookup.getDefinitionIdForObject(object)
    local entityId = WorldObjectIdentity.getEntityId(object)

    if entityId == nil then
        return nil
    end

    return EntityIndex.getDefinitionId(entityId)
end

function DefinitionLookup.getEffectiveDefinitionForObject(object)
    local definitionId = DefinitionLookup.getDefinitionIdForObject(object)

    if definitionId == nil then
        return nil
    end

    return Resolver.resolveDefinition(definitionId)
end

return DefinitionLookup
