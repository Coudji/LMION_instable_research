local DoorTransportIdentity = require "LMION/Runtime/Moveables/DoorTransportIdentity"
local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"

local SimpleDoorFlatpack = {}

local FLATPACK_ITEM_TYPE = "Base.LMION_Flatpack"

local function applyDisplayName(item)
    local scriptItem = ScriptManager.instance:FindItem(FLATPACK_ITEM_TYPE)
    if scriptItem ~= nil then
        item:setName(scriptItem:getDisplayName())
    end
end

local function applyWeight(item, weight)
    if item == nil or weight == nil then
        return
    end

    item:setActualWeight(weight)
    item:setWeight(weight)
    item:setCustomWeight(true)
end

function SimpleDoorFlatpack.getItemType()
    return FLATPACK_ITEM_TYPE
end

function SimpleDoorFlatpack.prepare(item, profile, state)
    if item == nil or type(profile) ~= "table" then
        return false
    end

    if item:getFullType() ~= FLATPACK_ITEM_TYPE then
        return false
    end

    if not DoorTransportIdentity.writeToItem(item, profile.definitionId) then
        return false
    end

    if state ~= nil then
        DoorTransportState.writeToItem(item, state)
    end

    applyDisplayName(item)
    applyWeight(item, profile.weight)
    return true
end

function SimpleDoorFlatpack.matchesProfile(item, profile)
    if item == nil or type(profile) ~= "table" or item.getFullType == nil then
        return false
    end

    if item:getFullType() ~= FLATPACK_ITEM_TYPE then
        return false
    end

    return DoorTransportIdentity.matches(item, profile.definitionId)
end

return SimpleDoorFlatpack
