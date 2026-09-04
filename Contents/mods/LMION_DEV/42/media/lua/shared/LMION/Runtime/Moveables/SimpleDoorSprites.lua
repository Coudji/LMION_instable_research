local SimpleDoorProfiles = require "LMION/Services/Moveables/SimpleDoorProfiles"

local SimpleDoorSprites = {}

local function markMoveable(spriteName)
    local sprite = getSprite(spriteName)
    if sprite == nil then
        return false
    end

    local properties = sprite:getProperties()
    if properties == nil then
        return false
    end

    properties:set("IsMoveAble")
    return true
end

function SimpleDoorSprites.configure()
    SimpleDoorProfiles.invalidate()

    local spriteNames = SimpleDoorProfiles.getConfiguredSpriteNames()
    local configured = 0

    for index = 1, #spriteNames do
        if markMoveable(spriteNames[index]) then
            configured = configured + 1
        end
    end

    print(string.format(
        "[LMION:DEV] Simple Moveables sprites configured: %d",
        configured
    ))

    return configured
end

return SimpleDoorSprites
