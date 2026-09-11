local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"
local GarageSpriteGrids = {}
local runtimeGrids = {}

local function mark(spriteName)
    local sprite=getSprite(spriteName)
    local properties=sprite and sprite:getProperties() or nil
    if properties then properties:set("IsMoveAble") end
end
local function makeGrid(profile,facing)
    local horizontal=facing=="N"; local grid=IsoSpriteGrid.new(horizontal and 3 or 1,horizontal and 1 or 3); if not grid then return false end
    local roles={"START","MIDDLE","END"}; local sprites={}
    for i,role in ipairs(roles) do
        local sprite=getSprite(profile.geometry[facing][role].closed); if not sprite then return false end; sprites[i]=sprite
        if horizontal then grid:setSprite(i-1,0,sprite) else grid:setSprite(0,3-i,sprite) end
    end
    if not grid:validate() then return false end
    for i=1,3 do sprites[i]:setSpriteGrid(grid) end
    runtimeGrids[profile.definitionId..":"..facing]=grid
    return true
end
function GarageSpriteGrids.configure()
    runtimeGrids={}; local installed=0; local ids=GarageProfiles.getDefinitionIds()
    for _,id in ipairs(ids) do local p=GarageProfiles.getByDefinitionId(id)
        for _,facing in ipairs({"N","W"}) do
            for _,role in ipairs({"START","MIDDLE","END"}) do mark(p.geometry[facing][role].closed);mark(p.geometry[facing][role].open) end
            if makeGrid(p,facing) then installed=installed+1 end
        end
    end
    print(string.format("[LMION:DEV] Garage runtime SpriteGrids configured: %d/%d",installed,#ids*2)); return installed==#ids*2
end
return GarageSpriteGrids
