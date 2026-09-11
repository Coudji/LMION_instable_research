local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"
local GarageSpriteGrids = {}

local function mark(spriteName)
    local sprite=getSprite(spriteName); if sprite and sprite:getProperties() then sprite:getProperties():Set("IsMoveAble", "true") end
end
local function makeGrid(profile, facing)
    local horizontal=facing=="N"; local grid=IsoSpriteGrid.new(horizontal and 3 or 1, horizontal and 1 or 3)
    local roles={"START","MIDDLE","END"}
    for i,role in ipairs(roles) do
        local sprite=getSprite(profile.geometry[facing][role].closed)
        if not sprite then return end
        if horizontal then grid:setSprite(i-1,0,sprite) else grid:setSprite(0,3-i,sprite) end
    end
    grid:initSpriteGrid()
end
function GarageSpriteGrids.configure()
    for _,id in ipairs(GarageProfiles.getDefinitionIds()) do
        local p=GarageProfiles.getByDefinitionId(id)
        for _,facing in ipairs({"N","W"}) do
            for _,role in ipairs({"START","MIDDLE","END"}) do
                mark(p.geometry[facing][role].closed); mark(p.geometry[facing][role].open)
            end
            makeGrid(p,facing)
        end
    end
    print("[LMION:DEV] Garage runtime SpriteGrids configured")
end
return GarageSpriteGrids
