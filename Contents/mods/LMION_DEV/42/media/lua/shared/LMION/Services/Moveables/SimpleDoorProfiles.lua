local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local SimpleDoorFlatpack = require "LMION/Services/Moveables/SimpleDoorFlatpack"

local SimpleDoorProfiles = {}

local PILOT_DEFINITION_ID = "Doors.Wood.WhitePanelDoor"

local profilesBySpriteName = nil

local function getSingleSkillLevel(skill)
    if type(skill) ~= "table" then
        return 0
    end

    local entryCount = 0
    local singleLevel = nil

    for _, level in pairs(skill) do
        entryCount = entryCount + 1
        if entryCount > 1 then
            return nil
        end

        singleLevel = level
    end

    if entryCount == 0 then
        return 0
    end

    return tonumber(singleLevel) or 0
end

local function getSingleToolName(tools)
    if type(tools) ~= "table" or #tools ~= 1 then
        return nil
    end

    local tool = tools[1]
    if type(tool) ~= "table" then
        return nil
    end

    if tool.tag == "base:screwdriver" then
        return "Screwdriver"
    end

    return nil
end

local function hasFlatpackScriptItem()
    return ScriptManager ~= nil
        and ScriptManager.instance ~= nil
        and ScriptManager.instance:FindItem(SimpleDoorFlatpack.getItemType()) ~= nil
end

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
    if definition.definitionId ~= PILOT_DEFINITION_ID or definition.doorType ~= "Simple" then
        return nil
    end

    if not hasFlatpackScriptItem() then
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

    local pickUpTool = getSingleToolName(pickup.tools)
    local placeTool = getSingleToolName(replacement.tools)
    local pickUpLevel = getSingleSkillLevel(pickup.skill)
    local packages = pickup.packages
    local weight = type(packages) == "table" and tonumber(packages.weight) or nil

    if pickUpTool == nil
        or placeTool == nil
        or pickUpLevel == nil
        or weight == nil then
        return nil
    end

    return {
        definitionId = definition.definitionId,
        itemType = SimpleDoorFlatpack.getItemType(),
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

function SimpleDoorProfiles.invalidate()
    profilesBySpriteName = nil
end

function SimpleDoorProfiles.getBySprite(sprite)
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

function SimpleDoorProfiles.getConfiguredSpriteNames()
    ensureBuilt()

    local names = {}
    for spriteName in pairs(profilesBySpriteName) do
        names[#names + 1] = spriteName
    end

    return names
end

return SimpleDoorProfiles
