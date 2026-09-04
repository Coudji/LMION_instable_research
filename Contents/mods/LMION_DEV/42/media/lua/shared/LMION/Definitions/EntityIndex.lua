local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local TableUtils = require "LMION/Support/TableUtils"

local EntityIndex = {}

local entityToDefinitionId = {}
local entityIds = {}
local indexedRevision = -1

local function requireEntityId(entityId, definitionId, field)
    if type(entityId) ~= "string" or entityId == "" then
        error(
            "LMION: definition "
                .. tostring(definitionId)
                .. " has an invalid GameEntity in "
                .. tostring(field),
            3
        )
    end

    return entityId
end

local function addMapping(index, ids, definitionId, entityId, field)
    entityId = requireEntityId(entityId, definitionId, field)

    local existingDefinitionId = index[entityId]

    if existingDefinitionId ~= nil and existingDefinitionId ~= definitionId then
        error(
            "LMION: GameEntity "
                .. entityId
                .. " is claimed by both "
                .. existingDefinitionId
                .. " and "
                .. definitionId,
            3
        )
    end

    if existingDefinitionId == nil then
        index[entityId] = definitionId
        ids[#ids + 1] = entityId
    end
end

local function indexDefinition(index, ids, definitionId, definition)
    if definition.entity ~= nil then
        addMapping(index, ids, definitionId, definition.entity, "entity")
    end

    local entities = definition.entities

    if type(entities) ~= "table" then
        return
    end

    if entities.left ~= nil then
        addMapping(index, ids, definitionId, entities.left, "entities.left")
    end

    if entities.right ~= nil then
        addMapping(index, ids, definitionId, entities.right, "entities.right")
    end
end

local function rebuild()
    local nextIndex = {}
    local nextEntityIds = {}
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)
        indexDefinition(nextIndex, nextEntityIds, definitionId, definition)
    end

    entityToDefinitionId = nextIndex
    entityIds = nextEntityIds
    indexedRevision = Registry.getRevision()
end

local function ensureCurrent()
    if indexedRevision ~= Registry.getRevision() then
        rebuild()
    end
end

function EntityIndex.getDefinitionId(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        error("LMION: entityId must be a non-empty string", 2)
    end

    ensureCurrent()

    return entityToDefinitionId[entityId]
end

function EntityIndex.getEntityIds()
    ensureCurrent()

    return TableUtils.deepCopy(entityIds)
end

return EntityIndex
