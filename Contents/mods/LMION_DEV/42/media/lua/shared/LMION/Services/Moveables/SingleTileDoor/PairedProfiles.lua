local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local PairedDoorProfiles = {}

local profilesBySpriteName = nil
local builtRevision = nil

local function getMemberFaces(definition, member)
    local geometry = definition.geometry
    local north = type(geometry) == "table" and geometry.N or nil
    local west = type(geometry) == "table" and geometry.W or nil
    local northMember = type(north) == "table" and north[member] or nil
    local westMember = type(west) == "table" and west[member] or nil

    if type(northMember) ~= "table" or type(westMember) ~= "table" then
        return nil
    end
    if type(northMember.closed) ~= "string" or northMember.closed == ""
        or type(westMember.closed) ~= "string" or westMember.closed == "" then
        return nil
    end

    return { N = northMember.closed, W = westMember.closed }
end

local function getMemberEntity(definition, member)
    local entities = definition.entities
    if type(entities) ~= "table" then
        return nil
    end

    local entityId = entities[member]
    return type(entityId) == "string" and entityId ~= "" and entityId or nil
end

local function buildMemberProfile(definition, member, frameSide)
    local entityId = getMemberEntity(definition, member)
    if entityId == nil then
        return nil
    end

    local itemType = MoveableProfileFields.getPackageItemType(
        definition,
        { entityId = entityId, member = member }
    )
    local faces = getMemberFaces(definition, member)

    if faces == nil or not MoveableProfileFields.hasScriptItem(itemType) then
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
        member = member,
        frameSide = frameSide,
        entityId = entityId,
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

local function addMemberSprites(index, profile, definition, member)
    for _, facing in ipairs({ "N", "W" }) do
        local orientation = definition.geometry and definition.geometry[facing] or nil
        local face = type(orientation) == "table" and orientation[member] or nil
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

local function addDefinition(index, definition)
    if definition.doorType ~= "Paired" then
        return
    end

    local left = buildMemberProfile(definition, "left", 1)
    local right = buildMemberProfile(definition, "right", 2)

    if left ~= nil then
        addMemberSprites(index, left, definition, "left")
    end
    if right ~= nil then
        addMemberSprites(index, right, definition, "right")
    end
end

local function buildIndex()
    local nextIndex = {}
    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        addDefinition(nextIndex, Resolver.resolveDefinition(definitionId))
    end
    profilesBySpriteName = nextIndex
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if profilesBySpriteName == nil or builtRevision ~= Registry.getRevision() then
        buildIndex()
    end
end

function PairedDoorProfiles.invalidate()
    profilesBySpriteName = nil
    builtRevision = nil
end

function PairedDoorProfiles.getBySprite(sprite)
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

function PairedDoorProfiles.getConfiguredSpriteNames()
    ensureBuilt()
    local names = {}
    for spriteName in pairs(profilesBySpriteName) do
        names[#names + 1] = spriteName
    end
    return names
end

return PairedDoorProfiles
