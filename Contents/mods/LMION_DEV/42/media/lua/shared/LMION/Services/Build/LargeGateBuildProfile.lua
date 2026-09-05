local LargeGateEntityNames = require "LMION/Runtime/Build/LargeGateEntityNames"
local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"

local LargeGateBuildProfile = {}

local LEAVES = { "A", "B" }
local profilesByEntityId = nil

local function addDefinition(index, definition)
    if definition == nil or definition.doorType ~= "LargeGate" then
        return
    end

    for leafIndex = 1, #LEAVES do
        local leaf = LEAVES[leafIndex]
        local entityId = LargeGateEntityNames.getLeafEntityId(definition, leaf)
        if entityId ~= nil then
            index[entityId] = {
                definition = definition,
                definitionId = definition.definitionId,
                doorType = "LargeGate",
                entityId = entityId,
                leaf = leaf,
            }
        end
    end
end

local function buildIndex()
    local index = {}
    local definitionIds = Registry.getDefinitionIds()

    for definitionIndex = 1, #definitionIds do
        addDefinition(index, Resolver.resolveDefinition(definitionIds[definitionIndex]))
    end

    profilesByEntityId = index
end

local function getEntityId(gameScript)
    if gameScript == nil then
        return nil
    end

    if gameScript.getFullName ~= nil then
        local fullName = gameScript:getFullName()
        if type(fullName) == "string" and fullName ~= "" then
            return fullName
        end
    end

    if gameScript.getName ~= nil then
        local name = gameScript:getName()
        if type(name) == "string" and name ~= "" then
            return "Base." .. name
        end
    end

    return nil
end

function LargeGateBuildProfile.getByGameScript(gameScript)
    if profilesByEntityId == nil then
        buildIndex()
    end

    local entityId = getEntityId(gameScript)
    return entityId and profilesByEntityId[entityId] or nil
end

return LargeGateBuildProfile
