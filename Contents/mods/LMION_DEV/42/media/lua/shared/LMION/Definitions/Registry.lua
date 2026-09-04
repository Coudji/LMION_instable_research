local TableUtils = require "LMION/Support/TableUtils"

local Registry = {}

local defaultsById = {}
local definitionsById = {}
local extensions = {}
local defaultIds = {}
local definitionIds = {}
local extensionIds = {}
local revision = 0

local function advanceRevision()
    revision = revision + 1
end

function Registry.registerDefault(definitionDefault)
    local defaultId = definitionDefault.defaultId

    if defaultsById[defaultId] ~= nil then
        error("LMION: definition default already registered: " .. defaultId, 2)
    end

    defaultsById[defaultId] = TableUtils.deepCopy(definitionDefault)
    defaultIds[#defaultIds + 1] = defaultId
    advanceRevision()

    return defaultId
end

function Registry.registerDefinition(definition)
    local definitionId = definition.definitionId

    if definitionsById[definitionId] ~= nil then
        error("LMION: definition already registered: " .. definitionId, 2)
    end

    definitionsById[definitionId] = TableUtils.deepCopy(definition)
    definitionIds[#definitionIds + 1] = definitionId
    advanceRevision()

    return definitionId
end

function Registry.registerExtension(extension)
    local extensionId = extension.extensionId

    if extensionIds[extensionId] then
        error("LMION: extension already registered: " .. extensionId, 2)
    end

    extensionIds[extensionId] = true
    extensions[#extensions + 1] = TableUtils.deepCopy(extension)
    advanceRevision()

    return extensionId
end

function Registry.getDefault(defaultId)
    return defaultsById[defaultId]
end

function Registry.getDefinition(definitionId)
    return definitionsById[definitionId]
end

function Registry.getExtensions()
    return extensions
end

function Registry.getDefaultIds()
    return TableUtils.deepCopy(defaultIds)
end

function Registry.getDefinitionIds()
    return TableUtils.deepCopy(definitionIds)
end

function Registry.getRevision()
    return revision
end

function Registry.getRegistrationStats()
    return {
        defaults = #defaultIds,
        definitions = #definitionIds,
        extensions = #extensions,
    }
end

return Registry
