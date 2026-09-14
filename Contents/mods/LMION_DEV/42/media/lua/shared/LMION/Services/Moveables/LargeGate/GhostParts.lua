local LargeGateTopology = require "LMION/Domain/LargeGateTopology"
local SpriteModel = require "LMION/PZ/SpriteModel"

local LargeGateGhostParts = {}

local function findPartIndex(facing, leaf, wantedLogicalIndex)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    if indices == nil then
        return nil
    end

    for partIndex = 1, 2 do
        if tonumber(indices[partIndex]) == wantedLogicalIndex then
            return partIndex
        end
    end

    return nil
end

local function getModelOwnerLogicalIndex(logicalIndex)
    if logicalIndex == 2 then
        return 1
    end
    if logicalIndex == 3 then
        return 4
    end
    return nil
end

function LargeGateGhostParts.shouldRender(profile, facing, leaf, partIndex, squares)
    if profile == nil or squares == nil then
        return true
    end

    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    local logicalIndex = indices and tonumber(indices[partIndex]) or nil
    if logicalIndex == nil then
        return true
    end

    local ownerLogicalIndex = getModelOwnerLogicalIndex(logicalIndex)
    if ownerLogicalIndex == nil then
        return true
    end

    local ownerPartIndex = findPartIndex(facing, leaf, ownerLogicalIndex)
    if ownerPartIndex == nil then
        return true
    end

    local ownerPart = profile.geometry[facing][leaf][ownerPartIndex]
    local ownerSquare = squares[ownerPartIndex]
    if ownerPart == nil or ownerSquare == nil then
        return true
    end

    return not SpriteModel.hasModel(ownerPart.closed, ownerSquare)
end

return LargeGateGhostParts
