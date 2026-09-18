local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local SingleEntityDoorProfiles = {}

local SUPPORTED_TYPES = {
    Simple = true,
    FenceGate = true,
    Sliding = true,
}

local profilesBySpriteName = nil
local builtRevision = nil

local function getClosedFaces(definition)
    local geometry = definition.geometry
    if type(geometry) ~= "table"
        or type(geometry.N) ~= "table"
        or type(geometry.W) ~= "table" then
        return nil
    end

    local north = geometry.N.closed
    local west = geometry.W.closed
    if type(north) ~= "string" or north == ""
        or type(west) ~= "string" or west == "" then
        return nil
    end

    return { N = north, W = west }
end

local function buildProfile(definition)
    if not SUPPORTED_TYPES[definition.doorType] then
        return nil
    end

    local itemType = MoveableProfileFields.getPackageItemType(
        definition,
        { entityId = definition.entity }
    )
    if not MoveableProfileFields.hasScriptItem(itemType) then
        return nil
    end

    local faces = getClosedFaces(definition)
    if faces == nil then
        return nil
    end

    local pickup = definition.pickup
    local replacement = definition.replacement
    if type(pickup) ~= "table" or type(replacement) ~= "table" then
        return nil
    end

    local weight = MoveableProfileFields.getPackageWeight(pickup)
    if weight == nil then
        return nil
    end

    return {
        definition = definition,
        definitionId = definition.definitionId,
        doorType = definition.doorType,
        entityId = definition.entity,
        itemType = itemType,
        faces = faces,
        pickUpTool = MoveableProfileFields.getToolName(definition, "pickup"),
        placeTool = MoveableProfileFields.getToolName(definition, "place"),
        pickUpLevel = MoveableProfileFields.getSkillLevel(definition, "pickup"),
        breakChance = MoveableProfileFields.getBreakChance(pickup),
        rawWeight = weight * 10,
        weight = weight,
    }
end

local function addProfileSprites(index, profile, definition)
    local geometry = definition.geometry

    for _, facing in ipairs({ "N", "W" }) do
        local face = geometry[facing]
        if type(face) == "table" then
            if type(face.closed) == "string" then
                index[face.closed] = profile
            end
            if type(face.open) == "string" then
                index[face.open] = profile
            end
        end
    end
end

local function buildIndex()
    local nextIndex = {}

    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        local definition = Resolver.resolveDefinition(definitionId)
        local profile = buildProfile(definition)
        if profile ~= nil then
            addProfileSprites(nextIndex, profile, definition)
        end
    end

    profilesBySpriteName = nextIndex
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if profilesBySpriteName == nil or builtRevision ~= Registry.getRevision() then
        buildIndex()
    end
end

function SingleEntityDoorProfiles.invalidate()
    profilesBySpriteName = nil
    builtRevision = nil
end

function SingleEntityDoorProfiles.getBySprite(sprite)
    if sprite == nil then
        return nil
    end
    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    local spriteName = sprite ~= nil and sprite:getName() or nil
    if spriteName == nil then
        return nil
    end

    ensureBuilt()
    return profilesBySpriteName[spriteName]
end

function SingleEntityDoorProfiles.getConfiguredSpriteNames()
    ensureBuilt()
    local names = {}
    for spriteName in pairs(profilesBySpriteName) do
        names[#names + 1] = spriteName
    end
    return names
end

return SingleEntityDoorProfiles
