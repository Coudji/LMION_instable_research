require "Moveables/ISMoveableSpriteProps"
local GarageParcelLookup={}

local function inventoryMatches(character,itemType)
    local out={}; local inv=character and character:getInventory() or nil; local items=inv and inv:getItems() or nil
    if items then for i=0,items:size()-1 do local item=items:get(i); if item and item:getFullType()==itemType then out[#out+1]={item=item,source=inv} end end end
    return out
end

function GarageParcelLookup.collect(character,itemType)
    local out=inventoryMatches(character,itemType); local square=character and character:getSquare() or nil
    if not square then return out end
    local radius=ISMoveableSpriteProps.multiSpriteFloorRadius or 3; local sx,sy,sz=square:getX(),square:getY(),square:getZ()
    for x=sx-radius,sx+radius do for y=sy-radius,sy+radius do
        local sq=getCell():getGridSquare(x,y,sz); local objects=sq and sq:getWorldObjects() or nil
        if objects then for i=0,objects:size()-1 do local wo=objects:get(i)
            if instanceof(wo,"IsoWorldInventoryObject") then local item=wo:getItem(); if item and item:getFullType()==itemType then out[#out+1]={item=item,source="floor",worldItem=wo} end end
        end end
    end end
    return out
end
return GarageParcelLookup
