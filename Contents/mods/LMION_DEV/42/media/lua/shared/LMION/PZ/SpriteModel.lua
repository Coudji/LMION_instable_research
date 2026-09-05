local SpriteModel = {}

local modelAvailabilityBySpriteName = {}

local function getSpriteName(sprite)
    if sprite == nil then
        return nil
    end
    if type(sprite) == "string" then
        return sprite
    end
    return sprite:getName()
end

function SpriteModel.hasModel(sprite, square)
    local spriteName = getSpriteName(sprite)
    if spriteName == nil or spriteName == "" then
        return false
    end

    local cached = modelAvailabilityBySpriteName[spriteName]
    if cached ~= nil then
        return cached
    end

    local resolved = type(sprite) == "string" and getSprite(sprite) or sprite
    if resolved == nil
        or square == nil
        or IsoObject == nil
        or IsoObject.new == nil then
        return false
    end

    local okObject, probe = pcall(IsoObject.new, getCell(), square, resolved)
    if not okObject or probe == nil or probe.getSpriteModel == nil then
        return false
    end

    local okModel, model = pcall(probe.getSpriteModel, probe)
    if not okModel then
        return false
    end

    local hasModel = model ~= nil
    modelAvailabilityBySpriteName[spriteName] = hasModel
    return hasModel
end

function SpriteModel.clearCache()
    modelAvailabilityBySpriteName = {}
end

return SpriteModel
