local DoorPlacement = require "LMION/Runtime/DoorPlacement"
local DoorSprite = require "LMION/PZ/DoorSprite"
local LargeGateDefinitionProfiles = require "LMION/Services/Common/LargeGateDefinitionProfiles"
local LargeGateMembers = require "LMION/Services/Common/LargeGateMembers"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGatePlacementSpace = {}

-- Native double-door leaves only move one tile away from their closed line.
-- Two tiles around each candidate footprint cell is therefore enough to find
-- every nearby LargeGate leaf that could share any closed/open position.
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

local function addFootprintEntry(index, list, square, state, partIndex)
    if square == nil then
        return false
    end

    local key = squareKey(square:getX(), square:getY(), square:getZ())
    local entry = index[key]

    if entry == nil then
        entry = {
            square = square,
            states = {},
            parts = {},
        }
        index[key] = entry
        list[#list + 1] = entry
    end

    entry.states[state] = true
    entry.parts[state .. ":" .. tostring(partIndex)] = true
    return true
end

local function buildFootprint(anchor, facing, leaf)
    if anchor == nil
        or (facing ~= "N" and facing ~= "W")
        or (leaf ~= "A" and leaf ~= "B") then
        return nil, nil
    end

    local index = {}
    local list = {}

    for _, state in ipairs({ "closed", "open" }) do
        for partIndex = 1, 2 do
            local offset = getStateOffset(facing, leaf, partIndex, state)
            local square = getSquare(anchor, offset)
            if not addFootprintEntry(index, list, square, state, partIndex) then
                return nil, nil
            end
        end
    end

    return index, list
end

local function footprintsOverlap(first, second)
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

local function hasLargeGateConflict(candidateFootprint, candidateEntries)
    local seenLeaves = {}

    for _, candidate in ipairs(candidateEntries) do
        local origin = candidate.square

        for dx = -NEIGHBOR_RADIUS, NEIGHBOR_RADIUS do
            for dy = -NEIGHBOR_RADIUS, NEIGHBOR_RADIUS do
                local square = getCell():getGridSquare(
                    origin:getX() + dx,
                    origin:getY() + dy,
                    origin:getZ()
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

                                local existingFootprint = buildFootprint(
                                    anchor,
                                    segment.facing,
                                    segment.leaf
                                )
                                if footprintsOverlap(candidateFootprint, existingFootprint) then
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

local function isOpenPositionClear(profile, anchor, facing, leaf, partIndex)
    local part = profile
        and profile.geometry
        and profile.geometry[facing]
        and profile.geometry[facing][leaf]
        and profile.geometry[facing][leaf][partIndex]
        or nil
    local offset = getStateOffset(facing, leaf, partIndex, "open")
    local square = getSquare(anchor, offset)

    if part == nil or square == nil then
        return false
    end

    if square.isVehicleIntersecting ~= nil and square:isVehicleIntersecting() then
        return false
    end

    if square.isFree ~= nil and not square:isFree(true) then
        return false
    end

    local openFacing = DoorSprite.getFacing(part.open) or facing
    return DoorPlacement.canPlaceUnframedAt(square, openFacing)
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
    local profile = LargeGateDefinitionProfiles.getByDefinitionId(definitionId)
    if profile == nil then
        return false, "missing-profile"
    end

    local footprint, entries = buildFootprint(anchor, facing, leaf)
    if footprint == nil or entries == nil then
        return false, "invalid-footprint"
    end

    for partIndex = 1, 2 do
        if not isOpenPositionClear(profile, anchor, facing, leaf, partIndex) then
            return false, "blocked-open-position"
        end
    end

    if hasLargeGateConflict(footprint, entries) then
        return false, "largegate-operational-conflict"
    end

    return true, "ok"
end

return LargeGatePlacementSpace
