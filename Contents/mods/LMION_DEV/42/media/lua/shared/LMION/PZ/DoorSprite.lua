local DoorSprite = {}

function DoorSprite.getFacing(sprite)
    if sprite == nil then
        return nil
    end

    if type(sprite) == "string" then
        sprite = getSprite(sprite)
    end

    local properties = sprite ~= nil and sprite:getProperties() or nil
    if properties == nil then
        return nil
    end

    if properties:has(IsoFlagType.doorN) then
        return "N"
    end

    if properties:has(IsoFlagType.doorW) then
        return "W"
    end

    return nil
end

return DoorSprite
