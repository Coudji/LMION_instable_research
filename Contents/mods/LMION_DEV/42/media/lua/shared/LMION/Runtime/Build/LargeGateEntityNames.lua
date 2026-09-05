local LargeGateEntityNames = {}

local VANILLA_BASE_ENTITIES = {
    ["Base.DoubleDoor"] = true,
    ["Base.DoubleWireGate"] = true,
    ["Base.DoubleFenceGate"] = true,
}

function LargeGateEntityNames.getLeafEntityId(definition, leaf)
    local entityId = type(definition) == "table" and definition.entity or nil
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    if leaf ~= "A" and leaf ~= "B" then
        return nil
    end

    if leaf == "A" and VANILLA_BASE_ENTITIES[entityId] then
        return entityId
    end

    return entityId .. leaf
end

function LargeGateEntityNames.isVanillaBaseEntity(entityId)
    return VANILLA_BASE_ENTITIES[entityId] == true
end

return LargeGateEntityNames
