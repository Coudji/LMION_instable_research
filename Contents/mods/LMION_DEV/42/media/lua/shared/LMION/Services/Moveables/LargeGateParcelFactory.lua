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

function LargeGateParcelFactory.create(profile, segment, object)
    if profile == nil or segment == nil or object == nil then
        return nil
    end

    local item = instanceItem(profile.itemType)
    if item == nil then
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
