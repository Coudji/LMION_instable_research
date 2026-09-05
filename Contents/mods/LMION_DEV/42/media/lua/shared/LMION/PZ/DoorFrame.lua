local DoorFrame = {}

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

local function getFrameClass(properties)
    if properties ~= nil and properties:has(IsoFlagType.DoubleDoor1) then
        return "paired-left"
    end
    if properties ~= nil and properties:has(IsoFlagType.DoubleDoor2) then
        return "paired-right"
    end

    return "standard"
end

local function isThumpableFrame(object, north, frameClass)
    if object == nil
        or not instanceof(object, "IsoThumpable")
        or object.isDoorFrame == nil
        or not object:isDoorFrame()
        or object.getNorth == nil
        or object:getNorth() ~= north then
        return false
    end

    return getFrameClass(getProperties(object)) == frameClass
end

local function isStaticFrame(object, north, frameClass)
    if object == nil or object.getType == nil then
        return false
    end

    local properties = getProperties(object)
    if getFrameClass(properties) ~= frameClass then
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

function DoorFrame.existsAt(square, north, frameClass)
    if square == nil or north == nil or type(frameClass) ~= "string" then
        return false
    end

    local specialObjects = square:getSpecialObjects()
    for index = 0, specialObjects:size() - 1 do
        if isThumpableFrame(specialObjects:get(index), north, frameClass) then
            return true
        end
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        if isStaticFrame(objects:get(index), north, frameClass) then
            return true
        end
    end

    return false
end

return DoorFrame
