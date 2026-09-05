local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local SingleTileProfileFields = require "LMION/Services/Moveables/SingleTileProfileFields"

local SingleEntityDoorProfiles = {}

local SUPPORTED_TYPES = {
    Simple = true,
    FenceGate = true,
    Sliding = true,
}

local profilesBySpriteName = nil

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

    return {
        N = north,
        W = west,
    }
end

local function buildProfile(definition)
    if not SUPPORTED_TYPES[definition.doorType] then
        return nil
    end

    local itemType = SingleTileProfileFields.getItemType(definition.entity)
    if not SingleTileProfileFields.hasScriptItem(itemType) then
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

    local pickUpTool = SingleTileProfileFields.getSingleToolName(pickup.tools, pickup.skill)
    local placeTool = SingleTileProfileFields.getSingleToolName(replacement.tools, pickup.skill)
    local pickUpLevel = SingleTileProfileFields.getSingleSkillLevel(pickup.skill)
    local weight = SingleTileProfileFields.getPackageWeight(pickup)

    if pickUpTool == nil
        or placeTool == nil
        or pickUpLevel == nil
        or weight == nil then
        return nil
    end

    return {
        definitionId = definition.definitionId,
        doorType = definition.doorType,
        entityId = definition.entity,
        itemType = itemType,
        faces = faces,
        pickUpTool = pickUpTool,
        placeTool = placeTool,
        pickUpLevel = pickUpLevel,
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
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definition = Resolver.resolveDefinition(definitionIds[index])
        local profile = buildProfile(definition)

        if profile ~= nil then
            addProfileSprites(nextIndex, profile, definition)
        end
    end

    profilesBySpriteName = nextIndex
end

local function ensureBuilt()
    if profilesBySpriteName == nil then
        buildIndex()
    end
end

function SingleEntityDoorProfiles.invalidate()
    profilesBySpriteName = nil
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
