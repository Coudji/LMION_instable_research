local LargeGateTopology = {}

local LEAF_INDICES = {
    N = {
        A = { 1, 2 },
        B = { 3, 4 },
    },
    W = {
        A = { 4, 3 },
        B = { 2, 1 },
    },
}

local STATE_OFFSETS = {
    N = {
        closed = {
            [1] = { 0, 0 },
            [2] = { 1, 0 },
            [3] = { 2, 0 },
            [4] = { 3, 0 },
        },
        open = {
            [1] = { 0, 0 },
            [2] = { 0, -1 },
            [3] = { 3, -1 },
            [4] = { 3, 0 },
        },
    },
    W = {
        closed = {
            [1] = { 0, 0 },
            [2] = { 0, 1 },
            [3] = { 0, 2 },
            [4] = { 0, 3 },
        },
        open = {
            [1] = { 0, 0 },
            [2] = { -1, 0 },
            [3] = { -1, 3 },
            [4] = { 0, 3 },
        },
    },
}

function LargeGateTopology.getLeafIndices(facing, leaf)
    local byLeaf = LEAF_INDICES[facing]
    return byLeaf and byLeaf[leaf] or nil
end

function LargeGateTopology.getStateOffset(facing, state, logicalIndex)
    local byState = STATE_OFFSETS[facing]
    local byIndex = byState and byState[state] or nil
    return byIndex and byIndex[logicalIndex] or nil
end

function LargeGateTopology.getPartnerLeaf(leaf)
    if leaf == "A" then
        return "B"
    end
    if leaf == "B" then
        return "A"
    end
    return nil
end

return LargeGateTopology
