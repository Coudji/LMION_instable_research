local CommonLargeGateProfiles = require "LMION/Services/Common/LargeGate/Profiles"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local LargeGateProfiles = {}

local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil

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

local function getSegmentItemType(entityId, leaf, partIndex)
    local baseItemType = MoveableProfileFields.getItemType(entityId)
    if baseItemType == nil then
        return nil
    end

    return baseItemType .. leaf .. "_Part" .. tostring(partIndex)
end

local function getSegmentItemTypes(commonProfile)
    local itemTypes = {}

    for _, leaf in ipairs(LEAVES) do
        itemTypes[leaf] = {}

        for partIndex = 1, 2 do
            local itemType = getSegmentItemType(commonProfile.entityId, leaf, partIndex)
            if not MoveableProfileFields.hasScriptItem(itemType) then
                return nil
            end
            itemTypes[leaf][partIndex] = itemType
        end
    end

    return itemTypes
end

local function buildProfile(commonProfile)
    local requirements = getTransportRequirements(commonProfile.definition)
    local itemTypes = getSegmentItemTypes(commonProfile)
    if requirements == nil or itemTypes == nil then
        return nil
    end

    return {
        definitionId = commonProfile.definitionId,
        displayName = commonProfile.displayName,
        entityId = commonProfile.entityId,
        doorType = commonProfile.doorType,
        definition = commonProfile.definition,
        geometry = commonProfile.geometry,
        itemTypes = itemTypes,
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
end

local function ensureBuilt()
    if profilesByDefinitionId == nil or segmentsBySpriteName == nil then
        buildIndexes()
    end
end

function LargeGateProfiles.invalidate()
    profilesByDefinitionId = nil
    segmentsBySpriteName = nil
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
