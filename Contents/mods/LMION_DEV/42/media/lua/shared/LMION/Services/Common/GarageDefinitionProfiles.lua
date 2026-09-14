local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"

local GarageDefinitionProfiles = {}

local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }

local profilesByDefinitionId = nil
local profilesByEntityId = nil
local segmentsBySpriteName = nil
local builtRevision = nil

local function getGameScriptEntityId(gameScript)
    if gameScript == nil then
        return nil
    end

    if gameScript.getFullName ~= nil then
        local fullName = gameScript:getFullName()
        if type(fullName) == "string" and fullName ~= "" then
            return fullName
        end
    end

    if gameScript.getName ~= nil then
        local name = gameScript:getName()
        if type(name) == "string" and name ~= "" then
            return "Base." .. name
        end
    end

    return nil
end

local function buildProfile(definition)
    if type(definition) ~= "table"
        or definition.doorType ~= "Garage"
        or type(definition.definitionId) ~= "string"
        or definition.definitionId == ""
        or type(definition.entity) ~= "string"
        or definition.entity == ""
        or type(definition.geometry) ~= "table" then
        return nil
    end

    for _, facing in ipairs(FACINGS) do
        local face = definition.geometry[facing]
        if type(face) ~= "table" then
            return nil
        end

        for _, role in ipairs(ROLES) do
            local part = face[role]
            if type(part) ~= "table"
                or type(part.closed) ~= "string"
                or part.closed == ""
                or type(part.open) ~= "string"
                or part.open == "" then
                return nil
            end
        end
    end

    return {
        definition = definition,
        definitionId = definition.definitionId,
        doorType = definition.doorType,
        entityId = definition.entity,
        geometry = definition.geometry,
    }
end

local function addProfileSegments(index, profile)
    for _, facing in ipairs(FACINGS) do
        for roleIndex, role in ipairs(ROLES) do
            local part = profile.geometry[facing][role]

            for _, isOpen in ipairs({ false, true }) do
                local spriteName = isOpen and part.open or part.closed
                if index[spriteName] ~= nil then
                    error("LMION: duplicate Garage sprite " .. spriteName, 3)
                end

                index[spriteName] = {
                    profile = profile,
                    definitionId = profile.definitionId,
                    facing = facing,
                    role = role,
                    roleIndex = roleIndex,
                    isOpen = isOpen,
                    spriteName = spriteName,
                }
            end
        end
    end
end

local function rebuild()
    local byDefinition = {}
    local byEntity = {}
    local bySprite = {}

    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        local definition = Resolver.resolveDefinition(definitionId)
        local profile = buildProfile(definition)

        if profile ~= nil then
            byDefinition[profile.definitionId] = profile
            byEntity[profile.entityId] = profile
            addProfileSegments(bySprite, profile)
        end
    end

    profilesByDefinitionId = byDefinition
    profilesByEntityId = byEntity
    segmentsBySpriteName = bySprite
    builtRevision = Registry.getRevision()
end

local function ensureBuilt()
    if builtRevision ~= Registry.getRevision() then
        rebuild()
    end
end

function GarageDefinitionProfiles.invalidate()
    profilesByDefinitionId = nil
    profilesByEntityId = nil
    segmentsBySpriteName = nil
    builtRevision = nil
end

function GarageDefinitionProfiles.getByDefinitionId(definitionId)
    ensureBuilt()
    return profilesByDefinitionId[definitionId]
end

function GarageDefinitionProfiles.getByEntityId(entityId)
    ensureBuilt()
    return profilesByEntityId[entityId]
end

function GarageDefinitionProfiles.getByGameScript(gameScript)
    local entityId = getGameScriptEntityId(gameScript)
    return entityId and GarageDefinitionProfiles.getByEntityId(entityId) or nil
end

function GarageDefinitionProfiles.getSegmentBySprite(sprite)
    if sprite == nil then
        return nil
    end

    local spriteName = type(sprite) == "string" and sprite or sprite:getName()
    ensureBuilt()
    return spriteName and segmentsBySpriteName[spriteName] or nil
end

function GarageDefinitionProfiles.getDefinitionIds()
    ensureBuilt()

    local ids = {}
    for definitionId in pairs(profilesByDefinitionId) do
        ids[#ids + 1] = definitionId
    end

    table.sort(ids)
    return ids
end

return GarageDefinitionProfiles
