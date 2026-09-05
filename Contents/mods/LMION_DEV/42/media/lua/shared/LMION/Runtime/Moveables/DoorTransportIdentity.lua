local DoorTransportIdentity = {}

local DEFINITION_ID_KEY = "lmionDoorDefinitionId"

function DoorTransportIdentity.writeToItem(item, definitionId)
    if item == nil or item.getModData == nil or type(definitionId) ~= "string" or definitionId == "" then
        return false
    end

    item:getModData()[DEFINITION_ID_KEY] = definitionId
    return true
end

function DoorTransportIdentity.readFromItem(item)
    if item == nil or item.getModData == nil then
        return nil
    end

    local definitionId = item:getModData()[DEFINITION_ID_KEY]
    if type(definitionId) ~= "string" or definitionId == "" then
        return nil
    end

    return definitionId
end

function DoorTransportIdentity.matches(item, definitionId)
    return DoorTransportIdentity.readFromItem(item) == definitionId
end

return DoorTransportIdentity
