local GarageBuild=require "LMION/Services/Build/GarageBuild"
local state=setmetatable({},{__mode="k"})
local function recipeData(logic) return logic and logic.getRecipeData and logic:getRecipeData() or nil end
local function barInput(logic)
 local data=recipeData(logic); local recipe=data and data:getRecipe() or nil; local inputs=recipe and recipe:getInputs() or nil; if not inputs then return nil end
 for i=0,inputs:size()-1 do local s=inputs:get(i); if s and s.isVariableAmount and s:isVariableAmount() then local possible=s:getPossibleInputItems(); local metal,iron=false,false; for j=0,possible:size()-1 do local ft=possible:get(j):getFullName(); metal=metal or ft=="Base.MetalBar"; iron=iron or ft=="Base.IronBar" end; if metal and iron then return data:getDataForInputScript(s) end end end
end
local function sync(logic,length)
 if logic and logic.setTargetVariableInputRatio then logic:setTargetVariableInputRatio(length/2) end
 local d=barInput(logic); local rd=recipeData(logic); if d and rd then while d:getInputItemCount()>length and d:getLastInputItem()~=nil do rd:removeInputItem(d:getLastInputItem()) end end
 local md=rd and rd:getModData() or nil; if md then md[GarageBuild.LengthModDataKey]=length end
end
function GarageBuild.getSelectedBarCount(logic) local d=barInput(logic); return d and d:getInputItemCount() or 0 end
function GarageBuild.getLengthFromLogic(logic)
 if not logic then return 3 end; local n=state[logic]; if n==nil then local rd=recipeData(logic); local md=rd and rd:getModData() or nil; n=md and md[GarageBuild.LengthModDataKey] or 3 end; n=GarageBuild.normalizeLength(n); state[logic]=n; sync(logic,n); return n
end
function GarageBuild.setLengthOnLogic(logic,length) if not GarageBuild.getProfileFromLogic(logic) then return nil end; length=GarageBuild.normalizeLength(length); state[logic]=length; sync(logic,length); return length end
function GarageBuild.ensureLengthOnLogic(logic) if not GarageBuild.getProfileFromLogic(logic) then return nil end; return GarageBuild.getLengthFromLogic(logic) end
return GarageBuild
