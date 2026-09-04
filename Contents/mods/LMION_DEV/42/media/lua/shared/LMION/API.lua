local DoorTypes = require "LMION/Domain/DoorTypes"
local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local Validation = require "LMION/Definitions/Validation"
local DefinitionLookup = require "LMION/Services/DefinitionLookup"

local API = {}

local function registerList(list, register)
    if list == nil then
        return
    end

    for index = 1, #list do
        register(list[index])
    end
end

function API.getAPIVersion()
    return 1
end

function API.registerDefault(definitionDefault)
    Validation.definitionDefault(definitionDefault)
    return Registry.registerDefault(definitionDefault)
end

function API.registerDefinition(definition)
    Validation.definition(definition)
    return Registry.registerDefinition(definition)
end

function API.registerExtension(extension)
    Validation.extension(extension)
    return Registry.registerExtension(extension)
end

function API.registerContent(content)
    Validation.content(content)
    registerList(content.defaults, API.registerDefault)
    registerList(content.definitions, API.registerDefinition)
    registerList(content.extensions, API.registerExtension)
end

function API.getEffectiveDefault(defaultId)
    return Resolver.resolveDefault(defaultId)
end

function API.getEffectiveDefinition(definitionId)
    return Resolver.resolveDefinition(definitionId)
end

function API.getDefinitionIdByEntity(entityId)
    return DefinitionLookup.getDefinitionIdByEntity(entityId)
end

function API.getEffectiveDefinitionByEntity(entityId)
    return DefinitionLookup.getEffectiveDefinitionByEntity(entityId)
end

function API.getEntityIdForObject(object)
    return DefinitionLookup.getEntityIdForObject(object)
end

function API.getDefinitionIdForObject(object)
    return DefinitionLookup.getDefinitionIdForObject(object)
end

function API.getEffectiveDefinitionForObject(object)
    return DefinitionLookup.getEffectiveDefinitionForObject(object)
end

function API.isDoorTypeSupported(doorType)
    return DoorTypes.isSupported(doorType)
end

function API.getSupportedDoorTypes()
    return DoorTypes.getNames()
end

function API.getDoorTypeFrameRequirement(doorType)
    return DoorTypes.getFrameRequirement(doorType)
end

function API.getRegisteredDefaultIds()
    return Registry.getDefaultIds()
end

function API.getRegisteredDefinitionIds()
    return Registry.getDefinitionIds()
end

function API.getRegistrationStats()
    return Registry.getRegistrationStats()
end

return API
