local Registry = require "LMION/Definitions/Registry"
local CommonGarageProfiles = require "LMION/Services/Common/Garage/Profiles"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local GarageProfiles = {}

local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }

local profilesByDefinitionId = nil
local segmentsBySpriteName = nil
local builtRevision = nil

local function shortName(entityId)
    if type(entityId) ~= "string" then
        return nil
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function buildProfile(commonProfile)
    if type(commonProfile) ~= "table" then
        return nil
    end

    local definition = commonProfile.definition
    local pickup = definition and definition.pickup or nil
    local replacement = definition and definition.replacement or nil
    local weight = MoveableProfileFields.getPackageWeight(pickup)
    local pickUpTool = MoveableProfileFields.getSingleToolName(
        pickup and pickup.tools,
        pickup and pickup.skill
    )
    local placeTool = MoveableProfileFields.getSingleToolName(
        replacement and replacement.tools,
        pickup and pickup.skill
    )
    local pickUpLevel = MoveableProfileFields.getSingleSkillLevel(
        pickup and pickup.skill
    )
    local entityName = shortName(commonProfile.entityId)

    if entityName == nil
        or weight == nil
        or pickUpTool == nil
        or placeTool == nil
        or pickUpLevel == nil then
        return nil
    end

    local itemTypes = {}
    for index = 1, 3 do
        local fullType = "Base.LMION_"
            .. entityName
            .. "_Part"
            .. tostring(index)

        if not MoveableProfileFields.hasScriptItem(fullType) then
            return nil
        end

        itemTypes[index] = fullType
    end

    return {
        definitionId = commonProfile.definitionId,
        entityId = commonProfile.entityId,
        doorType = commonProfile.doorType,
        definition = definition,
        geometry = commonProfile.geometry,
        itemTypes = itemTypes,
        pickUpTool = pickUpTool,
        placeTool = placeTool,
        pickUpLevel = pickUpLevel,
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
