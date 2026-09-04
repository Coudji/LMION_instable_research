local DoorState = require "LMION/Runtime/DoorState"

local DoorTransportState = {}

local HEALTH_KEY = "lmionDoorHealth"
local MAX_HEALTH_KEY = "lmionDoorMaxHealth"
local MAX_WAS_LOGICAL_KEY = "lmionDoorMaxWasLogical"

function DoorTransportState.capture(object)
    local state = DoorState.capture(object)
    if state == nil then
        return nil
    end

    return {
        health = state.health,
        maxHealth = state.maxHealth,
        maxWasLogical = state.hasLogicalMaxOverride == true,
    }
end

function DoorTransportState.writeToItem(item, state)
    if item == nil or type(state) ~= "table" or item.getModData == nil then
        return false
    end

    local modData = item:getModData()
    if state.health ~= nil then
        modData[HEALTH_KEY] = state.health
    end
    if state.maxHealth ~= nil then
        modData[MAX_HEALTH_KEY] = state.maxHealth
        modData[MAX_WAS_LOGICAL_KEY] = state.maxWasLogical == true
    end

    return true
end

function DoorTransportState.readFromItem(item)
    if item == nil or item.getModData == nil then
        return nil
    end

    local modData = item:getModData()
    if modData == nil then
        return nil
    end

    local health = tonumber(modData[HEALTH_KEY])
    local maxHealth = tonumber(modData[MAX_HEALTH_KEY])

    if health == nil and maxHealth == nil then
        return nil
    end

    return {
        health = health,
        maxHealth = maxHealth,
        maxWasLogical = modData[MAX_WAS_LOGICAL_KEY] == true,
    }
end

return DoorTransportState
