local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"

local LargeGateSpriteGrids = {}

local FACINGS = { "N", "W" }
local LEAVES = { "A", "B" }

local runtimeGrids = {}

local function getGridSize(facing)
    if facing == "N" then
        return 2, 1
    end
    if facing == "W" then
        return 1, 2
    end
    return nil, nil
end

local function setGridSprite(grid, facing, partIndex, sprite)
    if facing == "N" then
        grid:setSprite(partIndex - 1, 0, sprite)
        return
    end

    grid:setSprite(0, partIndex - 1, sprite)
end

local function installLeafGrid(profile, facing, leaf)
    local width, height = getGridSize(facing)
    local parts = profile.geometry[facing][leaf]
    if width == nil or parts == nil or IsoSpriteGrid == nil or IsoSpriteGrid.new == nil then
        return false
    end

    local grid = IsoSpriteGrid.new(width, height)
    if grid == nil then
        return false
    end

    local sprites = {}
    for partIndex = 1, 2 do
        local spriteName = parts[partIndex].closed
        local sprite = spriteName and getSprite(spriteName) or nil
        if sprite == nil then
            return false
        end

        setGridSprite(grid, facing, partIndex, sprite)
        sprites[partIndex] = sprite
    end

    if not grid:validate() then
        return false
    end

    for partIndex = 1, 2 do
        sprites[partIndex]:setSpriteGrid(grid)
    end

    runtimeGrids[profile.definitionId .. ":" .. facing .. ":" .. leaf] = grid
    return true
end

function LargeGateSpriteGrids.configure()
    LargeGateProfiles.invalidate()
    runtimeGrids = {}

    local definitionIds = LargeGateProfiles.getDefinitionIds()
    local installed = 0
    local expected = #definitionIds * #FACINGS * #LEAVES

    for definitionIndex = 1, #definitionIds do
        local profile = LargeGateProfiles.getByDefinitionId(definitionIds[definitionIndex])
        for facingIndex = 1, #FACINGS do
            local facing = FACINGS[facingIndex]
            for leafIndex = 1, #LEAVES do
                if installLeafGrid(profile, facing, LEAVES[leafIndex]) then
                    installed = installed + 1
                end
            end
        end
    end

    print(string.format(
        "[LMION:DEV] LargeGate sprite grids configured: %d/%d grids for %d definitions",
        installed,
        expected,
        #definitionIds
    ))

    return installed == expected
end

return LargeGateSpriteGrids
