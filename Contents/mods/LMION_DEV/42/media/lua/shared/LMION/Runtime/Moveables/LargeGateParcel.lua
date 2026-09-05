local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"

local LargeGateParcel = {}

local DEFINITION_KEY = "lmionLargeGateDefinitionId"
local LEAF_KEY = "lmionLargeGateLeaf"
local PART_KEY = "lmionLargeGatePart"

function LargeGateParcel.writeIdentity(item, segment)
    if item == nil or segment == nil or item.getModData == nil then
        return false
    end

    local modData = item:getModData()
    modData[DEFINITION_KEY] = segment.definitionId
    modData[LEAF_KEY] = segment.leaf
    modData[PART_KEY] = segment.partIndex
    return true
end

function LargeGateParcel.writeState(item, state)
    return DoorTransportState.writeToItem(item, state)
end

function LargeGateParcel.readIdentity(item)
    if item == nil or item.getModData == nil then
        return nil
    end

    local modData = item:getModData()
    if modData == nil then
        return nil
    end

    local definitionId = modData[DEFINITION_KEY]
    local leaf = modData[LEAF_KEY]
    local partIndex = tonumber(modData[PART_KEY])

    if type(definitionId) ~= "string"
        or definitionId == ""
        or (leaf ~= "A" and leaf ~= "B")
        or (partIndex ~= 1 and partIndex ~= 2) then
        return nil
    end

    return {
        definitionId = definitionId,
        leaf = leaf,
        partIndex = partIndex,
    }
end

function LargeGateParcel.readState(item)
    return DoorTransportState.readFromItem(item)
end

return LargeGateParcel
