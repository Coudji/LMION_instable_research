local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local LargeGateTopology = require "LMION/Domain/LargeGateTopology"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local LargeGateProfiles = {}

local PARCEL_ITEM_TYPE = "Base.LMION_OpeningParcel"
local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil

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

    for facingIndex = 1, #FACINGS do
        local facing = FACINGS[facingIndex]
        local face = geometry[facing]
        if type(face) ~= "table" then
            return false
        end

        for leafIndex = 1, #LEAVES do
            local leaf = LEAVES[leafIndex]
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

local function getPackageWeight(pickup)
    local packages = type(pickup) == "table" and pickup.packages or nil
    if type(packages) ~= "table" or tonumber(packages.count) ~= 2 then
        return nil
    end

    local weight = tonumber(packages.weight)
    if weight == nil or weight <= 0 then
        return nil
    end

    return weight
end

local function getTransportRequirements(definition)
    local pickup = definition.pickup
    local replacement = definition.replacement
    if type(pickup) ~= "table" or type(replacement) ~= "table" then
        return nil
    end

    local weight = getPackageWeight(pickup)
    local pickUpTool = MoveableProfileFields.getSingleToolName(pickup.tools, pickup.skill)
    local placeTool = MoveableProfileFields.getSingleToolName(replacement.tools, pickup.skill)
    local pickUpLevel = MoveableProfileFields.getSingleSkillLevel(pickup.skill)

    if weight == nil or pickUpTool == nil or placeTool == nil or pickUpLevel == nil then
        return nil
    end

    return {
        weight = weight,
        pickUpTool = pickUpTool,
        placeTool = placeTool,
        pickUpLevel = pickUpLevel,
    }
end

local function buildProfile(definition)
    if type(definition) ~= "table"
        or definition.doorType ~= "LargeGate"
        or type(definition.definitionId) ~= "string"
        or definition.definitionId == ""
        or not hasValidGeometry(definition)
        or not MoveableProfileFields.hasScriptItem(PARCEL_ITEM_TYPE) then
        return nil
    end

    local requirements = getTransportRequirements(definition)
    if requirements == nil then
        return nil
    end

    return {
        definitionId = definition.definitionId,
        displayName = definition.displayName,
        entityId = definition.entity,
        doorType = definition.doorType,
        definition = definition,
        geometry = definition.geometry,
        itemType = PARCEL_ITEM_TYPE,
        pickUpTool = requirements.pickUpTool,
        placeTool = requirements.placeTool,
        pickUpLevel = requirements.pickUpLevel,
        rawWeight = requirements.weight * 10,
        weight = requirements.weight,
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

local function indexProfileSprites(index, profile)
    for facingIndex = 1, #FACINGS do
        local facing = FACINGS[facingIndex]
        for leafIndex = 1, #LEAVES do
            local leaf = LEAVES[leafIndex]
            local parts = profile.geometry[facing][leaf]
            for partIndex = 1, 2 do
                local part = parts[partIndex]
                addSegment(index, profile, facing, leaf, partIndex, false, part.closed)
                addSegment(index, profile, facing, leaf, partIndex, true, part.open)
            end
        end
    end
end

local function buildIndexes()
    local nextProfiles = {}
    local nextSegments = {}
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definition = Resolver.resolveDefinition(definitionIds[index])
        local profile = buildProfile(definition)
        if profile ~= nil then
            nextProfiles[profile.definitionId] = profile
            indexProfileSprites(nextSegments, profile)
        end
    end

    profilesByDefinitionId = nextProfiles
    segmentsBySpriteName = nextSegments
end

local function ensureBuilt()
    if profilesByDefinitionId == nil or segmentsBySpriteName == nil then
        buildIndexes()
    end
end

function LargeGateProfiles.invalidate()
    profilesByDefinitionId = nil
    segmentsBySpriteName = nil
end

function LargeGateProfiles.getByDefinitionId(definitionId)
    ensureBuilt()
    return profilesByDefinitionId[definitionId]
end

function LargeGateProfiles.getSegmentBySprite(sprite)
    if sprite == nil then
        return nil
    end

    local spriteName = sprite
    if type(sprite) ~= "string" then
        spriteName = sprite:getName()
    end

    ensureBuilt()
    return spriteName and segmentsBySpriteName[spriteName] or nil
end

function LargeGateProfiles.getDefinitionIds()
    ensureBuilt()

    local ids = {}
    for definitionId in pairs(profilesByDefinitionId) do
        ids[#ids + 1] = definitionId
    end
    table.sort(ids)
    return ids
end

function LargeGateProfiles.getClosedSpriteNames()
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

return LargeGateProfiles
