local DoorObject = require "LMION/PZ/DoorObject"

local DoorDurability = {}

DoorDurability.MaxHealthModDataKey = "lmionDoorMaxHealth"

function DoorDurability.getHealth(object)
    if not DoorObject.isDoor(object) or object.getHealth == nil then
        return nil
    end

    return tonumber(object:getHealth())
end

function DoorDurability.setHealth(object, value)
    if not DoorObject.isDoor(object) or object.setHealth == nil then
        return nil
    end

    local health = tonumber(value)
    if health == nil then
        return nil
    end

    health = math.max(0, math.floor(health))
    object:setHealth(health)
    return health
end

function DoorDurability.hasMaxHealthOverride(object)
    if object == nil or object.getModData == nil then
        return false
    end

    local modData = object:getModData()
    return modData ~= nil
        and tonumber(modData[DoorDurability.MaxHealthModDataKey]) ~= nil
end

function DoorDurability.clearMaxHealthOverride(object)
    if object == nil or object.getModData == nil then
        return false
    end

    local modData = object:getModData()
    if modData == nil then
        return false
    end

    modData[DoorDurability.MaxHealthModDataKey] = nil
    return true
end

function DoorDurability.getEffectiveMaxHealth(object)
    if not DoorObject.isDoor(object) then
        return nil
    end

    if object.getModData ~= nil then
        local modData = object:getModData()
        local logicalMax = modData
            and tonumber(modData[DoorDurability.MaxHealthModDataKey])
            or nil

        if logicalMax ~= nil then
            return logicalMax
        end
    end

    if object.getMaxHealth ~= nil then
        return tonumber(object:getMaxHealth())
    end

    return nil
end

function DoorDurability.setEffectiveMaxHealth(object, value)
    if not DoorObject.isDoor(object) then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    maxHealth = math.max(0, math.floor(maxHealth))

    if DoorObject.isThumpableDoor(object) and object.setMaxHealth ~= nil then
        object:setMaxHealth(maxHealth)
        DoorDurability.clearMaxHealthOverride(object)
        return maxHealth
    end

    if object.getModData == nil then
        return nil
    end

    object:getModData()[DoorDurability.MaxHealthModDataKey] = maxHealth
    return maxHealth
end

function DoorDurability.restoreEffectiveMaxHealth(object, value, hadLogicalOverride)
    if not DoorObject.isDoor(object) then
        return nil
    end

    local maxHealth = tonumber(value)
    if maxHealth == nil then
        return nil
    end

    if DoorObject.isThumpableDoor(object) then
        return DoorDurability.setEffectiveMaxHealth(object, maxHealth)
    end

    local engineMaxHealth = object.getMaxHealth ~= nil
        and tonumber(object:getMaxHealth())
        or nil

    if hadLogicalOverride == true or engineMaxHealth ~= maxHealth then
        return DoorDurability.setEffectiveMaxHealth(object, maxHealth)
    end

    DoorDurability.clearMaxHealthOverride(object)
    return engineMaxHealth
end

return DoorDurability
