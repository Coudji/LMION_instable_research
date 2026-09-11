require "BuildingObjects/ISBuildingObject"
require "Moveables/ISMoveablesAction"
local GaragePlacement=require "LMION/Services/Moveables/GaragePlacement"
local GarageProfiles=require "LMION/Services/Moveables/GarageProfiles"

LMIONGaragePlacementAction=ISMoveablesAction:derive("LMIONGaragePlacementAction")
function LMIONGaragePlacementAction:isValid()
 local playerSquare=self.character and self.character:getSquare() or nil;if not playerSquare or not self.square or playerSquare:getZ()~=self.square:getZ() then return false end
 local p=GaragePlacement.buildPlan(self.character,self.definitionId,self.length,self.facing,self.square);if not p or not GaragePlacement.validate(self.character,p) then return false end
 if not ISMoveableDefinitions.cheat and not self.character:isMovablesCheat() then local adjacent=false;for i=1,p.length do local sq=p[i].square;if sq==playerSquare or playerSquare:isAdjacentTo(sq) then adjacent=true;break end end;if not adjacent then return false end end
 if isClient() and SafeHouse.isSafeHouse(self.square,self.character:getUsername(),true) and not SafeHouse.isSafehouseAllowLoot(self.square,self.character) then return false end
 return true
end
function LMIONGaragePlacementAction:complete()
 local p=GaragePlacement.buildPlan(self.character,self.definitionId,self.length,self.facing,self.square);if not p then return false end;local placed=GaragePlacement.place(self.character,p);if not placed then return false end
 if buildUtil and buildUtil.setHaveConstruction then for i=1,p.length do buildUtil.setHaveConstruction(p[i].square,true) end end;return true
end
function LMIONGaragePlacementAction:new(character,square,definitionId,length,facing)
 local o=ISBaseTimedAction.new(self,character);o.playerNum=character:getPlayerNum();o.square=square;o.definitionId=definitionId;o.length=length;o.facing=facing;o.mode="place";o.maxTime=o:getDuration();return o
end

LMIONGaragePlacementCursor=ISBuildingObject:derive("LMIONGaragePlacementCursor")
local function widthKey(id,fallback) if PZAPI and PZAPI.ModOptions then local options=PZAPI.ModOptions:getOptions("LMION_GaragePlacement");local option=options and options:getOption(id) or nil;if option then return option:getValue() end end;return fallback end
function LMIONGaragePlacementCursor:getPlan(square) return GaragePlacement.buildPlan(self.character,self.definitionId,self.selectedLength,self.facing,square) end
function LMIONGaragePlacementCursor:getMaximumLength() return GaragePlacement.getMaximumAvailableLength(self.character,self.definitionId) end
function LMIONGaragePlacementCursor:isValid(square) local m=self:getMaximumLength();if not m then return false end;self.selectedLength=math.max(2,math.min(self.selectedLength,m));local p=self:getPlan(square);return p~=nil and GaragePlacement.validate(self.character,p) end
local function floorGhost(square) local floor=square and square:getFloor() or nil;local sprite=floor and floor:getSprite() or nil;if sprite then sprite:RenderGhostTileColor(square:getX(),square:getY(),square:getZ(),0.75,1,0.75,0.25) end end
function LMIONGaragePlacementCursor:render(x,y,z,square)
 local p=self:getPlan(square);if not p then return end;local valid=GaragePlacement.validate(self.character,p);local r,g,b=valid and 0.5 or 1,valid and 1 or 0,valid and 0.5 or 0
 for i=1,p.length do local e=p[i];floorGhost(e.square);local sprite=getSprite(e.spriteName);if sprite then sprite:RenderGhostTileColor(e.square:getX(),e.square:getY(),e.square:getZ(),0,0,r,g,b,0.8) end end
end
function LMIONGaragePlacementCursor:rotateMouse(x,y) end
function LMIONGaragePlacementCursor:rotateKey(key)
 local less=widthKey("GarageWidthDecrease",Keyboard.KEY_SUBTRACT);local more=widthKey("GarageWidthIncrease",Keyboard.KEY_ADD)
 if key==less then local old=self.selectedLength;self.selectedLength=math.max(2,self.selectedLength-1);if old~=self.selectedLength then getSoundManager():playUISound("UIObjectMenuObjectRotateOutline") end;return end
 if key==more then local m=self:getMaximumLength();if m then local old=self.selectedLength;self.selectedLength=math.min(m,self.selectedLength+1);if old~=self.selectedLength then getSoundManager():playUISound("UIObjectMenuObjectRotateOutline") end end;return end
 if getCore():isKey("Rotate building",key) then self.facing=self.facing=="N" and "W" or "N";getSoundManager():playUISound("UIObjectMenuObjectRotateOutline") end
end
function LMIONGaragePlacementCursor:create(x,y,z,north,sprite)
 local square=getCell():getGridSquare(x,y,z);local p=self:getPlan(square);if not p or not GaragePlacement.validate(self.character,p) then return end
 local moveProps=ISMoveableSpriteProps.new(p[1].spriteName);if moveProps then moveProps.isMultiSprite=false end
 if ISMoveableDefinitions.cheat or (moveProps and moveProps:walkToAndEquip(self.character,square,"place",p[1].spriteName)) then ISTimedActionQueue.add(LMIONGaragePlacementAction:new(self.character,square,self.definitionId,self.selectedLength,self.facing)) end
end
function LMIONGaragePlacementCursor:new(character,definitionId,facing) local o=ISBuildingObject.new(self);o:init();o.character=character;o.player=character:getPlayerNum();o.definitionId=definitionId;o.facing=facing=="W" and "W" or "N";o.selectedLength=GaragePlacement.getMaximumAvailableLength(character,definitionId) or 2;o:setDragNilAfterPlace(true);o.noNeedHammer=true;return o end
function LMIONOpenGaragePlacementCursor(item,character)
 if not item or not character then return false end;local data=item:getModData();local definitionId=data and data.lmionGarageDefinitionId or nil;if not GarageProfiles.getByDefinitionId(definitionId) then return false end
 local facing="N";local worldSprite=item.getWorldSprite and item:getWorldSprite() or nil;local s=worldSprite and GarageProfiles.getSegmentBySprite(worldSprite) or nil;if s then facing=s.facing end;if not GaragePlacement.getMaximumAvailableLength(character,definitionId) then return false end
 local cursor=LMIONGaragePlacementCursor:new(character,definitionId,facing);getCell():setDrag(cursor,cursor.player);return true
end
