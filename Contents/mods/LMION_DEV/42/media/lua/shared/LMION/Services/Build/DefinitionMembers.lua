local LargeGateEntityNames = require "LMION/Runtime/Build/LargeGateEntityNames"

local DefinitionMembers = {}

local function add(result, seen, entityId, role)
    if type(entityId) ~= "string" or entityId == "" or seen[entityId] then
        return
    end

    seen[entityId] = true
    result[#result + 1] = {
        entityId = entityId,
        role = role,
    }
end

function DefinitionMembers.get(definition)
    local result = {}
    local seen = {}

    if type(definition) ~= "table" then
        return result
    end

    if definition.doorType == "LargeGate" then
        add(
            result,
            seen,
            LargeGateEntityNames.getLeafEntityId(definition, "A"),
            "A"
        )
        add(
            result,
            seen,
            LargeGateEntityNames.getLeafEntityId(definition, "B"),
            "B"
        )
        return result
    end

    add(result, seen, definition.entity, nil)

    local entities = definition.entities
    if type(entities) ~= "table" then
        return result
    end

    add(result, seen, entities.left, "left")
    add(result, seen, entities.right, "right")

    local extraKeys = {}
    for key, value in pairs(entities) do
        if key ~= "left"
            and key ~= "right"
            and type(value) == "string" then
            extraKeys[#extraKeys + 1] = key
        end
    end

    table.sort(extraKeys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    for index = 1, #extraKeys do
        local key = extraKeys[index]
        add(result, seen, entities[key], tostring(key))
    end

    return result
end

return DefinitionMembers
