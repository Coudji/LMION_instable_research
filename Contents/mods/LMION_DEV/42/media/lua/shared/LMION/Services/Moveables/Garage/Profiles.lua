local Registry = require "LMION/Definitions/Registry"
local CommonGarageProfiles = require "LMION/Services/Common/Garage/Profiles"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local GarageProfiles = {}

local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil
local builtRevision = nil

local function buildProfile(commonProfile)
    if type(commonProfile) ~= "table" then
        return nil
    end

    local definition = commonProfile.definition
    local pickup = definition and definition.pickup or nil
    local replacement = definition and definition.replacement or nil
    if type(pickup) ~= "table" or type(replacement) ~= "table" then
        return nil
    end

    local weight = MoveableProfileFields.getPackageWeight(pickup)
    if weight == nil then
        return nil
    end

    local itemTypes = {}
    for roleIndex, role in ipairs(ROLES) do
        local itemType = MoveableProfileFields.getPackageItemType(definition, {
            entityId = commonProfile.entityId,
            role = role,
            roleIndex = roleIndex,
            partIndex = roleIndex,
        })
        if not MoveableProfileFields.hasScriptItem(itemType) then
            return nil
        end
        itemTypes[roleIndex] = itemType
    end

    return {
        definitionId = commonProfile.definitionId,
        entityId = commonProfile.entityId,
        doorType = commonProfile.doorType,
        definition = definition,
        geometry = commonProfile.geometry,
        itemTypes = itemTypes,
        pickUpTool = MoveableProfileFields.getToolName(definition, "pickup"),
        placeTool = MoveableProfileFields.getToolName(definition, "place"),
        pickUpLevel = MoveableProfileFields.getSkillLevel(definition, "pickup"),
        breakChance = MoveableProfileFields.getBreakChance(pickup),
        rawWeight = weight * 10,
        weight = weight,
    }
end

local function rebuild()
    local profiles = {}
    local segments = {}

    for _, definitionId in ipairs(CommonGarageProfiles.getDefinitionIds()) do
        local commonProfile = CommonGarageProfiles.getByDefinitionId(definitionId)
        local profile = buildProfile(commonProfile)

        if profile ~= nil then
            profiles[definitionId] = profile

            for _, facing in ipairs(FACINGS) do
                for roleIndex, role in ipairs(ROLES) do
                    local part = profile.geometry[facing][role]
                    for _, isOpen in ipairs({ false, true }) do
                        local spriteName = isOpen and part.open or part.closed
                        if segments[spriteName] ~= nil then
                            error("LMION: duplicate Garage sprite " .. spriteName, 2)
                        end

                        segments[spriteName] = {
                            profile = profile,
                            definitionId = definitionId,
                            facing = facing,
                            role = role,
                            roleIndex = roleIndex,
                            isOpen = isOpen,
                            spriteName = spriteName,
                            itemType = profile.itemTypes[roleIndex],
                        }
                    end
                end
            end
        end
    end

    profilesByDefinitionId = profiles
    segmentsBySpriteName = segments
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if builtRevision ~= Registry.getRevision() then
        rebuild()
    end
end

function GarageProfiles.invalidate()
    profilesByDefinitionId = nil
    segmentsBySpriteName = nil
    builtRevision = nil
end

function GarageProfiles.getByDefinitionId(definitionId)
    ensureBuilt()
    return profilesByDefinitionId[definitionId]
end

function GarageProfiles.getSegmentBySprite(sprite)
    if sprite == nil then
        return nil
    end
    local spriteName = type(sprite) == "string" and sprite or sprite:getName()
    ensureBuilt()
    return spriteName and segmentsBySpriteName[spriteName] or nil
end

function GarageProfiles.getDefinitionIds()
    ensureBuilt()
    local ids = {}
    for definitionId in pairs(profilesByDefinitionId) do
        ids[#ids + 1] = definitionId
    end
    table.sort(ids)
    return ids
end

function GarageProfiles.getClosedSpriteNames()
    ensureBuilt()
    local names = {}
    for spriteName, segment in pairs(segmentsBySpriteName) do
        if not segment.isOpen then
            names[#names + 1] = spriteName
        end
    end
    table.sort(names)
    return names
end

return GarageProfiles
