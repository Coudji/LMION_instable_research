require "Moveables/ISMoveableSpriteProps"
local GarageLengthPolicy=require "LMION/Domain/GarageLengthPolicy"
local GarageParcelLookup=require "LMION/Services/Moveables/GarageParcelLookup"
local GarageProfiles=require "LMION/Services/Moveables/GarageProfiles"
local SingleTileDoorPlacementFinalizer=require "LMION/Services/Moveables/SingleTileDoorPlacementFinalizer"

local GaragePlacement={}
local roles={"START","MIDDLE","END"}

local function available(character,profile)
    return { START=GarageParcelLookup.collect(character,profile.itemTypes[1]), MIDDLE=GarageParcelLookup.collect(character,profile.itemTypes[2]), END=GarageParcelLookup.collect(character,profile.itemTypes[3]) }
end
local function maximum(parts)
    if not parts or #parts.START<1 or #parts.END<1 then return nil end
    local value=2+#parts.MIDDLE; local cap=GarageLengthPolicy.getMaximumLength(); return cap and math.min(value,cap) or value
end
function GaragePlacement.getMaximumAvailableLength(character,definitionId)
    local p=GarageProfiles.getByDefinitionId(definitionId); return p and maximum(available(character,p)) or nil
end
function GaragePlacement.buildPlan(character,definitionId,length,facing,startSquare)
    local p=GarageProfiles.getByDefinitionId(definitionId); length=tonumber(length)
    if not p or not startSquare or (facing~="N" and facing~="W") then return nil end
    local parts=available(character,p); local max=maximum(parts)
    if not max or not length or length<2 or length>max or not GarageLengthPolicy.isLengthAllowed(length) then return nil end
    local plan={length=length,definitionId=definitionId,facing=facing,profile=p}; local middle=1
    for pos=1,length do
        local role,parcel
        if pos==1 then role="START"; parcel=parts.START[1] elseif pos==length then role="END"; parcel=parts.END[1] else role="MIDDLE"; parcel=parts.MIDDLE[middle]; middle=middle+1 end
        local x=startSquare:getX()+(facing=="N" and pos-1 or 0); local y=startSquare:getY()-(facing=="W" and pos-1 or 0)
        local sq=getCell():getGridSquare(x,y,startSquare:getZ()); local sprite=p.geometry[facing][role].closed
        if not parcel or not sq or not sprite then return nil end
        plan[pos]={item=parcel.item,source=parcel.source,worldItem=parcel.worldItem,square=sq,spriteName=sprite,role=role}
    end
    return plan
end
local function props(entry) local p=ISMoveableSpriteProps.new(entry.spriteName); if p then p.isMultiSprite=false end; return p end
function GaragePlacement.validate(character,plan)
    if not character or not plan then return false end
    for i=1,plan.length do local e=plan[i]; local p=props(e); if not p or not e.item or not e.square or not p:canPlaceMoveableInternal(character,e.square,e.item) then return false end end
    return true
end
local function removePlaced(list)
    for i=#list,1,-1 do local o=list[i]; local sq=o and o:getSquare() or nil; if o and sq then sq:transmitRemoveItemFromSquare(o); sq:removeTileObject(o); sq:RecalcAllWithNeighbours(true) end end
end
local function consume(e)
    if e.source=="floor" then local wo=e.worldItem; local sq=wo and wo:getSquare() or nil; if not wo or not sq then return false end; sq:transmitRemoveItemFromSquare(wo); sq:removeWorldObject(wo); if e.item:getWorldItem()==wo then e.item:setWorldItem(nil) end; return true end
    if e.source and e.source.Remove then e.source:Remove(e.item); sendRemoveItemFromContainer(e.source,e.item); return true end
    return false
end
function GaragePlacement.place(character,plan)
    if not GaragePlacement.validate(character,plan) then return nil end
    local placed={}
    for i=1,plan.length do local e=plan[i]; local p=props(e); local raw=p and p:placeMoveableInternal(e.square,e.item,e.spriteName) or nil
        local final=raw and SingleTileDoorPlacementFinalizer.finalize(e.square,raw,e.item,e.spriteName,plan.profile) or nil
        if not final then removePlaced(placed); if raw and raw:getSquare() then removePlaced({raw}) end; return nil end
        placed[i]=final
    end
    for i=1,plan.length do if not consume(plan[i]) then print("[LMION:DEV] Garage parcel consumption failed after completed placement") end end
    return placed
end
return GaragePlacement
