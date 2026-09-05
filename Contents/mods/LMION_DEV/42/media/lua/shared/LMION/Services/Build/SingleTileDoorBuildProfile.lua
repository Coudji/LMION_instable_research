local EntityIndex = require "LMION/Definitions/EntityIndex"
local Resolver = require "LMION/Definitions/Resolver"

local SingleTileDoorBuildProfile = {}

local SUPPORTED_DEFINITIONS = {
    ["Doors.Wood.WhitePanelDoor"] = true,
    ["Doors.Wood.BlueChurchDoubleDoor"] = true,
}

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

local function getPairedMember(definition, entityId)
    local entities = definition.entities
    if type(entities) ~= "table" then
        return nil
    end

    if entities.left == entityId then
        return "left"
    end
    if entities.right == entityId then
        return "right"
    end

    return nil
end

function SingleTileDoorBuildProfile.getByGameScript(gameScript)
    local entityId = getEntityId(gameScript)
    if entityId == nil then
        return nil
    end

    local definitionId = EntityIndex.getDefinitionId(entityId)
    if definitionId == nil or not SUPPORTED_DEFINITIONS[definitionId] then
        return nil
    end

    local definition = Resolver.resolveDefinition(definitionId)
    if definition.doorType == "Simple" and definition.entity == entityId then
        return {
            definition = definition,
            definitionId = definitionId,
            doorType = "Simple",
            entityId = entityId,
        }
    end

    if definition.doorType == "Paired" then
        local member = getPairedMember(definition, entityId)
        if member ~= nil then
            return {
                definition = definition,
                definitionId = definitionId,
                doorType = "Paired",
                entityId = entityId,
                member = member,
            }
        end
    end

    return nil
end

return SingleTileDoorBuildProfile
