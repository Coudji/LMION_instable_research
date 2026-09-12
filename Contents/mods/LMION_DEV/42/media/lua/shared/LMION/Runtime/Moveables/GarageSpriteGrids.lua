local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"

local GarageSpriteGrids = {}

local FACINGS = { "N", "W" }
local ROLES = { "START", "MIDDLE", "END" }
local runtimeGrids = {}

local function markMoveable(spriteName)
    local sprite = getSprite(spriteName)
    local properties = sprite and sprite:getProperties() or nil

    if properties ~= nil then
        properties:set("IsMoveAble")
    end
end

local function installGrid(profile, facing)
    local horizontal = facing == "N"
    local width = horizontal and 3 or 1
    local height = horizontal and 1 or 3
    local grid = IsoSpriteGrid.new(width, height)

    if grid == nil then
        return false
    end

    local sprites = {}

    for index, role in ipairs(ROLES) do
        local sprite = getSprite(profile.geometry[facing][role].closed)
        if sprite == nil then
            return false
        end

        sprites[index] = sprite

        if horizontal then
            grid:setSprite(index - 1, 0, sprite)
        else
            grid:setSprite(0, 3 - index, sprite)
        end
    end

    if not grid:validate() then
        return false
    end

    for index = 1, 3 do
        sprites[index]:setSpriteGrid(grid)
    end

    runtimeGrids[profile.definitionId .. ":" .. facing] = grid
    return true
end

function GarageSpriteGrids.configure()
    runtimeGrids = {}

    local installed = 0
    local definitionIds = GarageProfiles.getDefinitionIds()

    for _, definitionId in ipairs(definitionIds) do
        local profile = GarageProfiles.getByDefinitionId(definitionId)

        for _, facing in ipairs(FACINGS) do
            for _, role in ipairs(ROLES) do
                local geometry = profile.geometry[facing][role]
                markMoveable(geometry.closed)
                markMoveable(geometry.open)
            end

            if installGrid(profile, facing) then
                installed = installed + 1
            end
        end
    end

    local expected = #definitionIds * #FACINGS
    print(string.format(
        "[LMION:DEV] Garage runtime SpriteGrids configured: %d/%d",
        installed,
        expected
    ))

    return installed == expected
end

return GarageSpriteGrids
