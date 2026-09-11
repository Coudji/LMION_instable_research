local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local MoveableProfileFields = require "LMION/Services/Moveables/MoveableProfileFields"

local GarageProfiles = {}
local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }
local profilesByDefinitionId, segmentsBySpriteName, builtRevision

local function shortName(entityId)
    return type(entityId) == "string" and (string.match(entityId, "^[^.]+%.(.+)$") or entityId) or nil
end

local function buildProfile(definition)
    if type(definition) ~= "table" or definition.doorType ~= "Garage" or type(definition.geometry) ~= "table" then return nil end
    local pickup, replacement = definition.pickup, definition.replacement
    local weight = MoveableProfileFields.getPackageWeight(pickup)
    local pickUpTool = MoveableProfileFields.getSingleToolName(pickup and pickup.tools, pickup and pickup.skill)
    local placeTool = MoveableProfileFields.getSingleToolName(replacement and replacement.tools, pickup and pickup.skill)
    local pickUpLevel = MoveableProfileFields.getSingleSkillLevel(pickup and pickup.skill)
    local name = shortName(definition.entity)
    if not name or not weight or not pickUpTool or not placeTool or pickUpLevel == nil then return nil end
    local itemTypes = {}
    for i = 1, 3 do
        local fullType = "Base.LMION_" .. name .. "_Part" .. tostring(i)
        if not MoveableProfileFields.hasScriptItem(fullType) then return nil end
        itemTypes[i] = fullType
    end
    for _, facing in ipairs(FACINGS) do
        for _, role in ipairs(ROLES) do
            local part = definition.geometry[facing] and definition.geometry[facing][role]
            if type(part) ~= "table" or type(part.closed) ~= "string" or type(part.open) ~= "string" then return nil end
        end
    end
    return { definitionId=definition.definitionId, entityId=definition.entity, definition=definition, geometry=definition.geometry,
        itemTypes=itemTypes, pickUpTool=pickUpTool, placeTool=placeTool, pickUpLevel=pickUpLevel,
        rawWeight=weight*10, weight=weight }
end

local function rebuild()
    local profiles, segments = {}, {}
    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        local profile = buildProfile(Resolver.resolveDefinition(definitionId))
        if profile then
            profiles[definitionId] = profile
            for _, facing in ipairs(FACINGS) do
                for roleIndex, role in ipairs(ROLES) do
                    local part = profile.geometry[facing][role]
                    for _, open in ipairs({false,true}) do
                        local spriteName = open and part.open or part.closed
                        if segments[spriteName] then error("LMION: duplicate Garage sprite " .. spriteName, 2) end
                        segments[spriteName] = { profile=profile, definitionId=definitionId, facing=facing, role=role,
                            roleIndex=roleIndex, isOpen=open, spriteName=spriteName, itemType=profile.itemTypes[roleIndex] }
                    end
                end
            end
        end
    end
    profilesByDefinitionId, segmentsBySpriteName, builtRevision = profiles, segments, Registry.getRevision()
end

local function ensureBuilt()
    if builtRevision ~= Registry.getRevision() then rebuild() end
end

function GarageProfiles.getByDefinitionId(id) ensureBuilt(); return profilesByDefinitionId[id] end
function GarageProfiles.getSegmentBySprite(sprite)
    if sprite == nil then return nil end
    local name = type(sprite) == "string" and sprite or sprite:getName()
    ensureBuilt(); return name and segmentsBySpriteName[name] or nil
end
function GarageProfiles.getDefinitionIds()
    ensureBuilt(); local ids = {}; for id in pairs(profilesByDefinitionId) do ids[#ids+1]=id end; table.sort(ids); return ids
end
function GarageProfiles.getClosedSpriteNames()
    ensureBuilt(); local names={}; for name,s in pairs(segmentsBySpriteName) do if not s.isOpen then names[#names+1]=name end end; table.sort(names); return names
end
return GarageProfiles
