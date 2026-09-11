local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"
local LargeGateParcel = require "LMION/Runtime/Moveables/LargeGateParcel"

local LargeGateParcelFactory = {}

local function getParcelName(profile, segment)
    return tostring(profile.displayName)
        .. " "
        .. tostring(segment.leaf)
        .. " ("
        .. tostring(segment.partIndex)
        .. "/2)"
end

local function getClosedSpriteName(profile, segment)
    local face = profile.geometry[segment.facing]
    local leaf = face and face[segment.leaf] or nil
    local part = leaf and leaf[segment.partIndex] or nil
    return part and part.closed or nil
end

function LargeGateParcelFactory.create(profile, segment, object)
    if profile == nil or segment == nil or object == nil then
        return nil
    end

    local closedSpriteName = getClosedSpriteName(profile, segment)
    local item = segment.itemType and instanceItem(segment.itemType) or nil
    if item == nil
        or not instanceof(item, "Moveable")
        or closedSpriteName == nil
        or not item:ReadFromWorldSprite(closedSpriteName) then
        return nil
    end

    item:setActualWeight(profile.weight)
    item:setWeight(profile.weight)
    item:setName(getParcelName(profile, segment))
    item:setCustomName(true)

    LargeGateParcel.writeIdentity(item, segment)
    LargeGateParcel.writeState(item, DoorTransportState.capture(object) or {})
    return item
end

return LargeGateParcelFactory
