require "Moveables/ISMoveableSpriteProps"
local GarageMoveProps=require "LMION/Services/Moveables/GarageMoveProps"
local GarageParcelLookup=require "LMION/Services/Moveables/GarageParcelLookup"
local GaragePlacement=require "LMION/Services/Moveables/GaragePlacement"

local Hook={}
local OPPOSITE={START="END",MIDDLE="MIDDLE",END="START"}

local function rotationFaces(segment)
    local p=segment and segment.profile; if not p then return nil end
    local opposite=OPPOSITE[segment.role]
    if segment.facing=="N" then return {N=p.geometry.N[segment.role].closed,W=p.geometry.W[opposite].closed} end
    return {N=p.geometry.N[opposite].closed,W=p.geometry.W[segment.role].closed}
end
local function startSquare(segment,square)
    if not segment or not square then return nil end
    local offset=(segment.roleIndex or 1)-1
    if segment.facing=="N" then return getCell():getGridSquare(square:getX()-offset,square:getY(),square:getZ()) end
    return getCell():getGridSquare(square:getX(),square:getY()+offset,square:getZ())
end
local function plan(self,character,square)
    local s=GarageMoveProps.getSegment(self); if not s then return nil end
    return GaragePlacement.buildPlan(character,s.definitionId,3,s.facing,startSquare(s,square))
end

function Hook.install()
    if ISMoveableSpriteProps._lmionV3GaragePlacementInstalled then return false end
    ISMoveableSpriteProps._lmionV3GaragePlacementInstalled=true
    local prevHas=ISMoveableSpriteProps.hasFaces; local prevGet=ISMoveableSpriteProps.getFaces; local prevIndexed=ISMoveableSpriteProps.getIndexedFaces
    local prevFindMulti=ISMoveableSpriteProps.findInInventoryMultiSprite; local prevCan=ISMoveableSpriteProps.canPlaceMoveable; local prevPlace=ISMoveableSpriteProps.placeMoveable

    ISMoveableSpriteProps.hasFaces=function(self) local s=GarageMoveProps.getSegment(self); local f=rotationFaces(s); if f then return f.N~=f.W end; return prevHas(self) end
    ISMoveableSpriteProps.getFaces=function(self) local s=GarageMoveProps.getSegment(self); local f=rotationFaces(s); if f then return f end; return prevGet(self) end
    ISMoveableSpriteProps.getIndexedFaces=function(self) local s=GarageMoveProps.getSegment(self); local f=rotationFaces(s); if f then return {f.N,f.W,f.N,f.W} end; return prevIndexed(self) end

    ISMoveableSpriteProps.findInInventoryMultiSprite=function(self,character,requestedName)
        local s=GarageMoveProps.getSegment(self); if not s then return prevFindMulti(self,character,requestedName) end
        local index=tonumber(string.match(requestedName or "","%((%d+)/3%)$")); if not index or index<1 or index>3 then return nil end
        if s.facing=="W" then index=4-index end
        local itemType=s.profile.itemTypes[index]; local found=GarageParcelLookup.collect(character,itemType); local e=found[1]
        return e and e.item or nil,e and e.source or nil
    end

    ISMoveableSpriteProps.canPlaceMoveable=function(self,character,square,item)
        if not GarageMoveProps.getSegment(self) then return prevCan(self,character,square,item) end
        local p=plan(self,character,square); return p~=nil and GaragePlacement.validate(character,p)
    end
    ISMoveableSpriteProps.placeMoveable=function(self,character,square,origSpriteName,forceAllow)
        local s=GarageMoveProps.getSegment(self); if not s then return prevPlace(self,character,square,origSpriteName,forceAllow) end
        local p=plan(self,character,square); local placed=GaragePlacement.place(character,p)
        if placed and buildUtil and buildUtil.setHaveConstruction then for i=1,#placed do buildUtil.setHaveConstruction(p[i].square,true) end end
        if ISMoveableCursor and ISMoveableCursor.clearCacheForAllPlayers then ISMoveableCursor.clearCacheForAllPlayers() end
        return placed
    end
    print("[LMION:DEV] Garage fixed-L3 toolbar placement hooks installed")
    return true
end
return Hook
