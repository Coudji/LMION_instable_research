local Registry = require "LMION/Definitions/Registry"
local CommonLargeGateProfiles = require "LMION/Services/Common/LargeGate/Profiles"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local LargeGateProfiles = {}

local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil
local builtRevision = nil

local function getPackageWeight(definition)
    local pickup = definition and definition.pickup or nil
    local packages = type(pickup) == "table" and pickup.packages or nil
    if type(packages) ~= "table" or tonumber(packages.count) ~= 2 then
        return nil
    end

    local weight = tonumber(packages.weight)
    return weight ~= nil and weight > 0 and weight or nil
end

local function getSegmentItemTypes(commonProfile)
    local result = {}
    local definition = commonProfile.definition

    for _, leaf in ipairs(LEAVES) do
        result[leaf] = {}
        for partIndex = 1, 2 do
            local itemType = MoveableProfileFields.getPackageItemType(definition, {
                entityId = commonProfile.entityId,
                leaf = leaf,
                partIndex = partIndex,
            })
            if not MoveableProfileFields.hasScriptItem(itemType) then
                return nil
            end
            result[leaf][partIndex] = itemType
        end
    end

    return result
end

local function buildProfile(commonProfile)
    local definition = commonProfile.definition
    local weight = getPackageWeight(definition)
    local itemTypes = getSegmentItemTypes(commonProfile)
    if weight == nil or itemTypes == nil then
        return nil
    end

    return {
        definitionId = commonProfile.definitionId,
        displayName = commonProfile.displayName,
        entityId = commonProfile.entityId,
        doorType = commonProfile.doorType,
        definition = definition,
        geometry = commonProfile.geometry,
        itemTypes = itemTypes,
        pickUpTool = MoveableProfileFields.getToolName(definition, "pickup"),
        placeTool = MoveableProfileFields.getToolName(definition, "place"),
        pickUpLevel = MoveableProfileFields.getSkillLevel(definition, "pickup"),
        breakChance = MoveableProfileFields.getBreakChance(definition.pickup),
        rawWeight = weight * 10,
        weight = weight,
    }
end

local function addSegment(index, profile, facing, leaf, partIndex, isOpen, spriteName)
    if index[spriteName] ~= nil then
        error("LMION: duplicate LargeGate sprite " .. tostring(spriteName), 3)
    end

    local commonSegment = CommonLargeGateProfiles.getSegmentBySprite(spriteName)
    index[spriteName] = {
        profile = profile,
        definitionId = profile.definitionId,
        facing = facing,
        leaf = leaf,
        partIndex = partIndex,
        logicalIndex = commonSegment and commonSegment.logicalIndex or nil,
        isOpen = isOpen,
        spriteName = spriteName,
        itemType = profile.itemTypes[leaf][partIndex],
    }
end

local function indexProfileSprites(index, profile)
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

local function buildIndexes()
    local nextProfiles = {}
    local nextSegments = {}

    for _, definitionId in ipairs(CommonLargeGateProfiles.getDefinitionIds()) do
        local commonProfile = CommonLargeGateProfiles.getByDefinitionId(definitionId)
        local profile = buildProfile(commonProfile)
        if profile ~= nil then
            nextProfiles[profile.definitionId] = profile
            indexProfileSprites(nextSegments, profile)
        end
    end

    profilesByDefinitionId = nextProfiles
    segmentsBySpriteName = nextSegments
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if profilesByDefinitionId == nil
        or segmentsBySpriteName == nil
        or builtRevision ~= Registry.getRevision() then
        buildIndexes()
    end
end

function LargeGateProfiles.invalidate()
    profilesByDefinitionId = nil
    segmentsBySpriteName = nil
    builtRevision = nil
    CommonLargeGateProfiles.invalidate()
end

function LargeGateProfiles.getByDefinitionId(definitionId)
    ensureBuilt()
    return profilesByDefinitionId[definitionId]
end

function LargeGateProfiles.getSegmentBySprite(sprite)
    if sprite == nil then
        return nil
    end
    local spriteName = type(sprite) == "string" and sprite or sprite:getName()
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
