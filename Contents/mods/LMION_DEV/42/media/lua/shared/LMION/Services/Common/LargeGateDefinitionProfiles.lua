local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"

local LargeGateDefinitionProfiles = {}

local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil
local builtRevision = nil

local function isPart(part)
    return type(part) == "table"
        and type(part.closed) == "string"
        and part.closed ~= ""
        and type(part.open) == "string"
        and part.open ~= ""
end

local function hasValidGeometry(definition)
    local geometry = definition.geometry
    if type(geometry) ~= "table" then
        return false
    end

    for _, facing in ipairs(FACINGS) do
        local face = geometry[facing]
        if type(face) ~= "table" then
            return false
        end

        for _, leaf in ipairs(LEAVES) do
            local parts = face[leaf]
            if type(parts) ~= "table"
                or not isPart(parts[1])
                or not isPart(parts[2]) then
                return false
            end
        end
    end

    return true
end

local function buildProfile(definition)
    if type(definition) ~= "table"
        or definition.doorType ~= "LargeGate"
        or type(definition.definitionId) ~= "string"
        or definition.definitionId == ""
        or type(definition.entity) ~= "string"
        or definition.entity == ""
        or not hasValidGeometry(definition) then
        return nil
    end

    return {
        definition = definition,
        definitionId = definition.definitionId,
        displayName = definition.displayName,
        doorType = definition.doorType,
        entityId = definition.entity,
        geometry = definition.geometry,
    }
end

local function addSegment(index, profile, facing, leaf, partIndex, isOpen, spriteName)
    if index[spriteName] ~= nil then
        error("LMION: duplicate LargeGate sprite " .. tostring(spriteName), 3)
    end

    local indices = LargeGateTopology.getLeafIndices(facing, leaf)
    index[spriteName] = {
        profile = profile,
        definitionId = profile.definitionId,
        facing = facing,
        leaf = leaf,
        partIndex = partIndex,
        logicalIndex = indices and indices[partIndex] or nil,
        isOpen = isOpen,
        spriteName = spriteName,
    }
end

local function addProfileSegments(index, profile)
    for _, facing in ipairs(FACINGS) do
        for _, leaf in ipairs(LEAVES) do
            local parts = profile.geometry[facing][leaf]
            for partIndex = 1, 2 do
                local part = parts[partIndex]
                addSegment(index, profile, facing, leaf, partIndex, false, part.closed)
                addSegment(index, profile, facing, leaf, partIndex, true, part.open)
            end
        end
    end
end

local function rebuild()
    local byDefinition = {}
    local bySprite = {}

    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        local definition = Resolver.resolveDefinition(definitionId)
        local profile = buildProfile(definition)

        if profile ~= nil then
            byDefinition[profile.definitionId] = profile
            addProfileSegments(bySprite, profile)
        end
    end

    profilesByDefinitionId = byDefinition
    segmentsBySpriteName = bySprite
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if builtRevision ~= Registry.getRevision() then
        rebuild()
    end
end

function LargeGateDefinitionProfiles.invalidate()
    profilesByDefinitionId = nil
    segmentsBySpriteName = nil
    builtRevision = nil
end

function LargeGateDefinitionProfiles.getByDefinitionId(definitionId)
    ensureBuilt()
    return profilesByDefinitionId[definitionId]
end

function LargeGateDefinitionProfiles.getSegmentBySprite(sprite)
    if sprite == nil then
        return nil
    end

    local spriteName = type(sprite) == "string" and sprite or sprite:getName()
    ensureBuilt()
    return spriteName and segmentsBySpriteName[spriteName] or nil
end

function LargeGateDefinitionProfiles.getDefinitionIds()
    ensureBuilt()

    local ids = {}
    for definitionId in pairs(profilesByDefinitionId) do
        ids[#ids + 1] = definitionId
    end

    table.sort(ids)
    return ids
end

function LargeGateDefinitionProfiles.getClosedSpriteNames()
    ensureBuilt()

    local names = {}
    for spriteName, segment in pairs(segmentsBySpriteName) do
        if segment.isOpen == false then
            names[#names + 1] = spriteName
        end
    end

    table.sort(names)
    return names
end

return LargeGateDefinitionProfiles
