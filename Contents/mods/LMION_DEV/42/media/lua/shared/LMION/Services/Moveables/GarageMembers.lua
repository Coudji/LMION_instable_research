local DoorObject = require "LMION/PZ/DoorObject"
local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"

local GarageMembers = {}
local ROLE_BY_INDEX = { [1]="START", [2]="MIDDLE", [3]="END" }

local function getRole(object)
    if object == nil or IsoDoor == nil or IsoDoor.getGarageDoorIndex == nil then return nil end
    return ROLE_BY_INDEX[tonumber(IsoDoor.getGarageDoorIndex(object))]
end

function GarageMembers.getSegmentForObject(object)
    local sprite=object and object:getSprite() or nil
    return sprite and GarageProfiles.getSegmentBySprite(sprite) or nil
end

function GarageMembers.getChain(source)
    if source == nil or not DoorObject.isIsoDoor(source) or IsoDoor.getGarageDoorFirst == nil or IsoDoor.getGarageDoorNext == nil then return nil end
    local first=IsoDoor.getGarageDoorFirst(source)
    if first == nil or getRole(first) ~= "START" then return nil end
    local north, expectedOpen = first:getNorth(), first:IsOpen()
    local out, current, previous = {}, first, nil
    while current ~= nil do
        if not DoorObject.isIsoDoor(current) or current:getNorth() ~= north or current:IsOpen() ~= expectedOpen then return nil end
        local role=getRole(current)
        if role == nil or (#out > 0 and role == "START") then return nil end
        out[#out+1]=current
        if role == "END" then return #out >= 2 and out or nil end
        previous=current; current=IsoDoor.getGarageDoorNext(current)
        if current == previous then return nil end
    end
    return nil
end

function GarageMembers.getMembers(source, expectedDefinitionId)
    local chain=GarageMembers.getChain(source); if not chain then return nil end
    local expectedOpen=source:IsOpen(); local members={}
    for i,object in ipairs(chain) do
        local segment=GarageMembers.getSegmentForObject(object); local role=getRole(object)
        local expectedRole=(i==1 and "START") or (i==#chain and "END") or "MIDDLE"
        if not segment or segment.definitionId ~= expectedDefinitionId or segment.role ~= role or role ~= expectedRole or segment.isOpen ~= expectedOpen then return nil end
        local closed=segment.profile.geometry[segment.facing][role].closed
        members[i]={object=object,square=object:getSquare(),segment=segment,role=role,closedSpriteName=closed}
    end
    return members
end

return GarageMembers
