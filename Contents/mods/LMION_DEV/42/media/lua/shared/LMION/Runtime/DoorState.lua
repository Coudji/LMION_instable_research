local DoorObject = require "LMION/PZ/DoorObject"
local DoorDurability = require "LMION/Runtime/DoorDurability"
local TableUtils = require "LMION/Support/TableUtils"

local DoorState = {}

local function copyModData(object)
    if object == nil or object.getModData == nil then
        return nil
    end

    local modData = object:getModData()
    if modData == nil then
        return nil
    end

    return TableUtils.deepCopy(modData)
end

local function getKeyId(object)
    if object == nil or object.getKeyId == nil then
        return nil
    end

    return object:getKeyId()
end

local function getLocked(object)
    if object == nil or object.isLocked == nil then
        return nil
    end

    return object:isLocked()
end

local function getLockedByKey(object)
    if object == nil or object.isLockedByKey == nil then
        return nil
    end

    return object:isLockedByKey()
end

local function restoreModData(object, state)
    if state.modData == nil or object.setModData == nil then
        return
    end

    object:setModData(TableUtils.deepCopy(state.modData))
end

local function restoreDurability(object, state)
    if state.maxHealth ~= nil then
        DoorDurability.restoreEffectiveMaxHealth(
            object,
            state.maxHealth,
            state.hasLogicalMaxOverride == true
        )
    end

    if state.health ~= nil then
        DoorDurability.setHealth(object, state.health)
    end
end

local function restoreLockState(object, state)
    if state.keyId ~= nil and object.setKeyId ~= nil then
        object:setKeyId(state.keyId)
    end

    if state.locked ~= nil and object.setIsLocked ~= nil then
        object:setIsLocked(state.locked)
    end

    if state.lockedByKey ~= nil and object.setLockedByKey ~= nil then
        object:setLockedByKey(state.lockedByKey)
    end
end

function DoorState.capture(object)
    if not DoorObject.isDoor(object) then
        return nil
    end

    return {
        representation = DoorObject.getRepresentation(object),
        facing = DoorObject.getFacing(object),
        health = DoorDurability.getHealth(object),
        maxHealth = DoorDurability.getEffectiveMaxHealth(object),
        hasLogicalMaxOverride = DoorDurability.hasMaxHealthOverride(object),
        keyId = getKeyId(object),
        locked = getLocked(object),
        lockedByKey = getLockedByKey(object),
        modData = copyModData(object),
    }
end

function DoorState.restore(object, state)
    if not DoorObject.isDoor(object) or type(state) ~= "table" then
        return false
    end

    restoreModData(object, state)
    restoreDurability(object, state)
    restoreLockState(object, state)

    return true
end

return DoorState
