require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"
local GarageBuild=require "LMION/Services/Build/GarageLengthState"
local GarageLengthPolicy=require "LMION/Domain/GarageLengthPolicy"
local H=getTextManager():getFontHeight(UIFont.Small)+8

LMIONGarageLengthSelector=ISPanel:derive("LMIONGarageLengthSelector")
function LMIONGarageLengthSelector:initialise() ISPanel.initialise(self) end
function LMIONGarageLengthSelector:createChildren()
 ISPanel.createChildren(self)
 self.label=ISLabel:new(0,0,H,getText("IGUI_LMION_GarageBuild_Length"),1,1,1,1,UIFont.Small,true);self.label:initialise();self.label:instantiate();self:addChild(self.label)
 self.less=ISButton:new(0,0,H,H,"-",self,LMIONGarageLengthSelector.onClick);self.less:initialise();self.less:instantiate();self:addChild(self.less)
 self.value=ISLabel:new(0,0,H,"3",1,1,1,1,UIFont.Small,true);self.value:initialise();self.value:instantiate();self:addChild(self.value)
 self.more=ISButton:new(0,0,H,H,"+",self,LMIONGarageLengthSelector.onClick);self.more:initialise();self.more:instantiate();self:addChild(self.more);self:updateState()
end
function LMIONGarageLengthSelector:updateState() local l=GarageBuild.getLengthFromLogic(self.logic);self.value:setName(tostring(l));self.less.enable=l>2;local m=GarageLengthPolicy.getMaximumLength();self.more.enable=m==nil or l<m end
function LMIONGarageLengthSelector:setLength(l) if GarageBuild.setLengthOnLogic(self.logic,l) then self:updateState();if self.panel then self.panel:xuiRecalculateLayout() end end end
function LMIONGarageLengthSelector:onClick(button) local l=GarageBuild.getLengthFromLogic(self.logic);self:setLength(l+(button==self.less and -1 or 1)) end
function LMIONGarageLengthSelector:calculateLayout(w,h) w=math.max(w or 0,180);h=math.max(h or 0,H+16);local x,y=8,8;self.label:setX(x);self.label:setY(y);x=self.label:getRight()+8;self.less:setX(x);self.less:setY(y);x=self.less:getRight()+8;self.value:setX(x);self.value:setY(y);x=x+32;self.more:setX(x);self.more:setY(y);self:setWidth(w);self:setHeight(h) end
function LMIONGarageLengthSelector:new(player,logic,panel) local o=ISPanel:new(0,0,180,H+16);setmetatable(o,self);self.__index=self;o.player=player;o.logic=logic;o.panel=panel;o.background=false;return o end

local function context(logic) local p=GarageBuild.getProfileFromLogic(logic);return p,p and GarageBuild.ensureLengthOnLogic(logic) or nil end
local function containers(logic) return logic and logic.getContainers and logic:getContainers() or nil end
local previousDynamic=ISBuildRecipePanel.createDynamicChildren
ISBuildRecipePanel.createDynamicChildren=function(self) previousDynamic(self);local p=context(self.logic);if not p or not self.rootTable then self.lmionGarageLengthSelector=nil;return end;local s=LMIONGarageLengthSelector:new(self.player,self.logic,self);s:initialise();s:instantiate();self.lmionGarageLengthSelector=s;self.rootTable:setElement(0,1,s);self:xuiRecalculateLayout() end
local function inputFullType(widget) local s=widget and widget.inputScript;local items=s and s.getPossibleInputItems and s:getPossibleInputItems() or nil;if not items or items:size()<1 then return nil end;return items:get(0):getFullName() end
local previousInput=ISWidgetInput.updateValues
ISWidgetInput.updateValues=function(self)
 previousInput(self);local p,l=context(self.logic);if not p or not self.primary or not self.primary.label then return end;local full=inputFullType(self);local req,key=GarageBuild.getRequirement(p,l,full);if not req then return end
 local avail=GarageBuild.getAvailable(self.player,key,req.uses,containers(self.logic));local ok=avail>=req.amount;local txt=req.uses and ((ok and tostring(req.amount) or tostring(avail).."/"..tostring(req.amount)).." "..getText("Attributes_Type_Uses")) or tostring(avail).."/"..tostring(req.amount)
 self.primary.label:setName(txt);self.primary.label.amountValue=req.amount;self.primary.label.satisfiedValue=avail;if ok then self.primary.label.textColor=self.textColor;self.borderColor=self.normalBorderColor;self.primary.icon.backgroundColor.a=1 else self.primary.label.textColor=self.colBad;self.borderColor=self.colBad;if avail<=0 then self.primary.icon.backgroundColor.a=0.25 end end
end
local previousTitle=ISWidgetTitleHeader.updateLabels
ISWidgetTitleHeader.updateLabels=function(self)
 previousTitle(self);local p,l=context(self.logic);if not p or not self.errorLabel or self.player:isBuildCheat() then return end
 if not GarageBuild.hasRequirements(self.player,p,l,containers(self.logic)) or not GarageBuild.hasSelectedBars(self.logic,l) then local text=getText("IGUI_CraftingWindow_Error_NotAvailable")..getText("IGUI_CraftingWindow_Error_Inputs");self.errorLabel.errorText=text;self.errorLabel:setName(text);self.errorLabel:setVisible(true) end
end
local previousControl=ISWidgetBuildControl.prerender
ISWidgetBuildControl.prerender=function(self) previousControl(self);local p,l=context(self.logic);if p and self.buttonCraft and not self.player:isBuildCheat() then self.buttonCraft.enable=self.buttonCraft.enable and GarageBuild.hasRequirements(self.player,p,l,containers(self.logic)) and GarageBuild.hasSelectedBars(self.logic,l) end end
local previousCreate=ISBuildPanel.createBuildIsoEntity
ISBuildPanel.createBuildIsoEntity=function(self,dontSetDrag)
 local p,l=context(self.logic);if p and self._lmionGarageRepeatLength then l=GarageBuild.normalizeLength(self._lmionGarageRepeatLength) end;local r=previousCreate(self,dontSetDrag)
 if p and self.buildEntity then self.buildEntity.lmionGarageLength=l;self.buildEntity.lmionGarageDefinitionId=p.definitionId;if not self.player:isBuildCheat() then self.buildEntity.blockBuild=self.buildEntity.blockBuild or not GarageBuild.hasRequirements(self.player,p,l,containers(self.logic)) or not GarageBuild.hasSelectedBars(self.logic,l) end end;return r
end
local previousStop=ISBuildPanel.onStopCraft
ISBuildPanel.onStopCraft=function(self)
 local p,l=context(self.logic);if not p then return previousStop(self) end;self._lmionGarageRepeatLength=l;local ok,r=pcall(previousStop,self);self._lmionGarageRepeatLength=nil;GarageBuild.setLengthOnLogic(self.logic,l);if self.buildEntity then self.buildEntity.lmionGarageLength=l end;local s=self.craftRecipePanel and self.craftRecipePanel.lmionGarageLengthSelector or nil;if s then s:updateState() end;if not ok then error(r) end;return r
end
