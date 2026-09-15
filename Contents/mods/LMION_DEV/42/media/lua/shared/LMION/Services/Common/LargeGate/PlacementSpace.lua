local LargeGateProfiles = require "LMION/Services/Common/LargeGate/Profiles"
local LargeGateMembers = require "LMION/Services/Common/LargeGate/Members"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGatePlacementSpace = {}

-- Native double-door leaves sweep a 2x2 area. Search two tiles around that
-- sweep so every nearby LargeGate leaf whose own sweep could overlap is found.
local NEIGHBOR_RADIUS = 2

local function getSquare(anchor, offset)
    if anchor == nil or offset == nil then
        return nil
    end

    return getCell():getGridSquare(
        anchor.x + tonumber(offset[1]),
        anchor.y + tonumber(offset[2]),
        anchor.z
    )
end

local function squareKey(x, y, z)
    return table.concat({ tostring(x), tostring(y), tostring(z) }, ":")
end

local function getStateOffset(facing, leaf, partIndex, state)
    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    local logicalIndex = indices and indices[partIndex] or nil
    return logicalIndex
        and LargeGateTopology.getStateOffset(facing, state, logicalIndex)
        or nil
end

local function getEndpointSquares(anchor, facing, leaf)
    local squares = {}

    for _, state in ipairs({ "closed", "open" }) do
        for partIndex = 1, 2 do
            local square = getSquare(
                anchor,
                getStateOffset(facing, leaf, partIndex, state)
            )
            if square == nil then
                return nil
            end
            squares[#squares + 1] = square
        end
    end

    return squares
end

local function buildSweep(anchor, facing, leaf)
    if anchor == nil
        or (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B") then
        return nil, nil
    end

    local endpoints = getEndpointSquares(anchor, facing, leaf)
    if endpoints == nil then
        return nil, nil
    end

    local minX = endpoints[1]:getX()
    local maxX = minX
    local minY = endpoints[1]:getY()
    local maxY = minY
    local z = endpoints[1]:getZ()

    for index = 2, #endpoints do
        local square = endpoints[index]
        minX = math.min(minX, square:getX())
        maxX = math.max(maxX, square:getX())
        minY = math.min(minY, square:getY())
        maxY = math.max(maxY, square:getY())
    end

    -- LMION LargeGate topology is PZ's native two-tile leaf: closed and open
    -- positions are two adjacent sides of one 2x2 swing square.
    if maxX - minX ~= 1 or maxY - minY ~= 1 then
        return nil, nil
    end

    local index = {}
    local list = {}

    for y = minY, maxY do
        for x = minX, maxX do
            local square = getCell():getGridSquare(x, y, z)
            if square == nil then
                return nil, nil
            end

            local key = squareKey(x, y, z)
            index[key] = square
            list[#list + 1] = square
        end
    end

    return index, list
end

local function sweepsOverlap(first, second)
    if first == nil or second == nil then
        return false
    end

    for key in pairs(first) do
        if second[key] ~= nil then
            return true
        end
    end

    return false
end

local function hasSolidObstacle(square)
    if square == nil then
        return true
    end

    if square:isSolid() or square:isSolidTrans() then
        return true
    end

    if IsoObjectType ~= nil
        and IsoObjectType.tree ~= nil
        and square:has(IsoObjectType.tree) then
        return true
    end

    if square.isVehicleIntersecting ~= nil and square:isVehicleIntersecting() then
        return true
    end

    return false
end

local function hasSweepObstacle(sweepList)
    if sweepList == nil or #sweepList ~= 4 then
        return true
    end

    local minX, maxX = nil, nil
    local minY, maxY = nil, nil
    local z = sweepList[1]:getZ()

    for index = 1, #sweepList do
        local square = sweepList[index]
        if hasSolidObstacle(square) then
            return true
        end

        local x = square:getX()
        local y = square:getY()
        minX = minX == nil and x or math.min(minX, x)
        maxX = maxX == nil and x or math.max(maxX, x)
        minY = minY == nil and y or math.min(minY, y)
        maxY = maxY == nil and y or math.max(maxY, y)
    end

    local topLeft = getCell():getGridSquare(minX, minY, z)
    local topRight = getCell():getGridSquare(maxX, minY, z)
    local bottomRight = getCell():getGridSquare(maxX, maxY, z)
    local bottomLeft = getCell():getGridSquare(minX, maxY, z)

    if topLeft == nil
        or topRight == nil
        or bottomRight == nil
        or bottomLeft == nil then
        return true
    end

    -- Mirrors IsoDoor's native double-door obstruction test: check the three
    -- paths across the 2x2 swing square. IsoGridSquare:isSomethingTo includes
    -- walls, windows and doors, including diagonal paths through either edge.
    return topLeft:isSomethingTo(topRight)
        or topLeft:isSomethingTo(bottomRight)
        or topLeft:isSomethingTo(bottomLeft)
end

local function getAnchorFromSegment(square, segment)
    if square == nil or segment == nil then
        return nil
    end

    local state = segment.isOpen and "open" or "closed"
    local offset = getStateOffset(
        segment.facing,
        segment.leaf,
        segment.partIndex,
        state
    )
    if offset == nil then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end

local function getLeafKey(anchor, segment)
    if anchor == nil or segment == nil then
        return nil
    end

    return table.concat({
        tostring(anchor.x),
        tostring(anchor.y),
        tostring(anchor.z),
        tostring(segment.facing),
        tostring(segment.definitionId),
        tostring(segment.leaf),
    }, ":")
end

local function hasLargeGateConflict(candidateSweep, candidateSquares)
    local seenLeaves = {}

    for _, candidateSquare in ipairs(candidateSquares) do
        for dx = -NEIGHBOR_RADIUS, NEIGHBOR_RADIUS do
            for dy = -NEIGHBOR_RADIUS, NEIGHBOR_RADIUS do
                local square = getCell():getGridSquare(
                    candidateSquare:getX() + dx,
                    candidateSquare:getY() + dy,
                    candidateSquare:getZ()
                )
                local objects = square and square:getSpecialObjects() or nil

                if objects ~= nil then
                    for objectIndex = 0, objects:size() - 1 do
                        local object = objects:get(objectIndex)
                        local segment = LargeGateMembers.getSegmentForObject(object)

                        if segment ~= nil then
                            local anchor = getAnchorFromSegment(square, segment)
                            local leafKey = getLeafKey(anchor, segment)

                            if leafKey ~= nil and seenLeaves[leafKey] ~= true then
                                seenLeaves[leafKey] = true

                                local existingSweep = buildSweep(
                                    anchor,
                                    segment.facing,
                                    segment.leaf
                                )
                                if sweepsOverlap(candidateSweep, existingSweep) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

function LargeGatePlacementSpace.getAnchor(square, facing, leaf, partIndex, state)
    local offset = getStateOffset(
        facing,
        leaf,
        partIndex,
        state or "closed"
    )
    if square == nil or offset == nil then
        return nil
    end

    return {
        x = square:getX() - tonumber(offset[1]),
        y = square:getY() - tonumber(offset[2]),
        z = square:getZ(),
    }
end

function LargeGatePlacementSpace.getPartSquare(anchor, facing, leaf, partIndex, state)
    return getSquare(anchor, getStateOffset(facing, leaf, partIndex, state))
end

function LargeGatePlacementSpace.validate(definitionId, anchor, facing, leaf)
    if LargeGateProfiles.getByDefinitionId(definitionId) == nil then
        return false, "missing-profile"
    end

    local sweep, sweepSquares = buildSweep(anchor, facing, leaf)
    if sweep == nil or sweepSquares == nil then
        return false, "invalid-sweep"
    end

    if hasSweepObstacle(sweepSquares) then
        return false, "blocked-swing-area"
    end

    -- This second, state-independent check protects existing LargeGate leaves as
    -- well: a candidate may not occupy any square swept by another leaf, even if
    -- that square is empty in the other leaf's current open/closed state.
    if hasLargeGateConflict(sweep, sweepSquares) then
        return false, "largegate-swing-conflict"
    end

    return true, "ok"
end

return LargeGatePlacementSpace
