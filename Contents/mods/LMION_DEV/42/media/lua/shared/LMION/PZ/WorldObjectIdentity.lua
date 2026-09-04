local WorldObjectIdentity = {}

function WorldObjectIdentity.getEntityId(object)
    if object == nil then
        error("LMION: object identity requires a world object", 2)
    end

    local entityScript = object:getEntityScript()

    if entityScript == nil then
        return nil
    end

    local entityId = entityScript:getFullName()

    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return entityId
end

return WorldObjectIdentity
