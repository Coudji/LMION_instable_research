local GarageBuild=require "LMION/Services/Build/GarageBuild"
local state=setmetatable({},{__mode="k"})
local function recipeData(logic) return logic and logic.getRecipeData and logic:getRecipeData() or nil end
local function barInput(logic)
 local data=recipeData(logic);local recipe=data and data.getRecipe and data:getRecipe() or nil;local inputs=recipe and recipe.getInputs and recipe:getInputs() or nil;if not inputs then return nil end
 for i=0,inputs:size()-1 do local s=inputs:get(i);if s and s.isVariableAmount and s:isVariableAmount() then local possible=s:getPossibleInputItems();local metal,iron=false,false
  if possible then for j=0,possible:size()-1 do local item=possible:get(j);local ft=item and item.getFullName and item:getFullName() or nil;metal=metal or ft=="Base.MetalBar";iron=iron or ft=="Base.IronBar" end end
  if metal and iron then return data:getDataForInputScript(s) end
 end end
end
local function sync(logic,length)
 if logic and logic.setTargetVariableInputRatio then logic:setTargetVariableInputRatio(length/GarageBuild.MinLength) end
 local d=barInput(logic);local rd=recipeData(logic);if d and rd then while d:getInputItemCount()>length and d:getLastInputItem()~=nil do rd:removeInputItem(d:getLastInputItem()) end end
 local md=rd and rd.getModData and rd:getModData() or nil;if md then md[GarageBuild.LengthModDataKey]=length end
end
function GarageBuild.getSelectedBarCount(logic) local d=barInput(logic);return d and d.getInputItemCount and d:getInputItemCount() or 0 end
function GarageBuild.hasSelectedBars(logic,length) if not GarageBuild.getProfileFromLogic(logic) then return true end;return GarageBuild.getSelectedBarCount(logic)>=GarageBuild.normalizeLength(length) end
function GarageBuild.getLengthFromLogic(logic)
 if not logic then return GarageBuild.DefaultLength end;local n=tonumber(state[logic]);if n==nil then local rd=recipeData(logic);local md=rd and rd.getModData and rd:getModData() or nil;n=md and tonumber(md[GarageBuild.LengthModDataKey]) or GarageBuild.DefaultLength end
 n=GarageBuild.normalizeLength(n);state[logic]=n;sync(logic,n);return n
end
function GarageBuild.setLengthOnLogic(logic,length) if not GarageBuild.getProfileFromLogic(logic) then return nil end;length=GarageBuild.normalizeLength(length);state[logic]=length;sync(logic,length);return length end
function GarageBuild.ensureLengthOnLogic(logic) if not GarageBuild.getProfileFromLogic(logic) then return nil end;return GarageBuild.getLengthFromLogic(logic) end
return GarageBuild
