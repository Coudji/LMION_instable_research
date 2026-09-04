local StandardDoorFrame = {}

local function getProperties(object)
    if object == nil or object.getSprite == nil then
        return nil
    end

    local sprite = object:getSprite()
    if sprite == nil then
        return nil
    end

    return sprite:getProperties()
end

local function hasPairedFrameFlag(properties)
    if properties == nil then
        return false
    end

    return properties:has(IsoFlagType.DoubleDoor1)
        or properties:has(IsoFlagType.DoubleDoor2)
end

local function isThumpableFrame(object, north)
    if object == nil
        or not instanceof(object, "IsoThumpable")
        or object.isDoorFrame == nil
        or not object:isDoorFrame()
        or object.getNorth == nil
        or object:getNorth() ~= north then
        return false
    end

    return not hasPairedFrameFlag(getProperties(object))
end

local function isStaticFrame(object, north)
    if object == nil or object.getType == nil then
        return false
    end

    local properties = getProperties(object)
    if hasPairedFrameFlag(properties) then
        return false
    end

    local objectType = object:getType()
    if north and objectType == IsoObjectType.doorFrN then
        return true
    end
    if not north and objectType == IsoObjectType.doorFrW then
        return true
    end

    if properties == nil then
        return false
    end

    if north then
        return properties:has("DoorWallN")
    end

    return properties:has("DoorWallW")
end

function StandardDoorFrame.existsAt(square, north)
    if square == nil or north == nil then
        return false
    end

    local specialObjects = square:getSpecialObjects()
    for index = 0, specialObjects:size() - 1 do
        if isThumpableFrame(specialObjects:get(index), north) then
            return true
        end
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        if isStaticFrame(objects:get(index), north) then
            return true
        end
    end

    return false
end

return StandardDoorFrame
