local GarageLengthPolicy=require "LMION/Domain/GarageLengthPolicy"
local GarageProfiles=require "LMION/Services/Moveables/GarageProfiles"
local GarageBuild={DefaultLength=3,MinLength=2,LengthModDataKey="LMIONGarageBuildLength"}
local RESOURCE_TYPES={"Base.BlowTorch","Base.SmallSheetMetal","Base.GlassPanel","Base.MetalBar","Base.IronBar","Base.Hinge","Base.WeldingRods"}
local BASE={solid={BlowTorch=1,SmallSheetMetal=6,Bars=2,Hinge=4,WeldingRods=2},glazed={BlowTorch=1,SmallSheetMetal=4,GlassPanel=2,Bars=2,Hinge=4,WeldingRods=2}}
local lastConsumed=setmetatable({},{__mode="k"})

function GarageBuild.normalizeLength(length)
    length=math.max(2,math.floor(tonumber(length) or 3)); local max=GarageLengthPolicy.getMaximumLength(); return max and math.min(length,max) or length
end
local function gameScript(objectInfo) local s=objectInfo and objectInfo.getScript and objectInfo:getScript() or nil; return s and s:getParent() or nil end
function GarageBuild.getProfileFromObjectInfo(objectInfo)
    local script=gameScript(objectInfo); if not script then return nil end
    local full=script.getFullName and script:getFullName() or ("Base."..tostring(script:getName()));
    for _,id in ipairs(GarageProfiles.getDefinitionIds()) do local p=GarageProfiles.getByDefinitionId(id); if p.entityId==full or string.match(p.entityId,"[^.]+$")==script:getName() then return p end end
    return nil
end
function GarageBuild.getProfileFromLogic(logic) return GarageBuild.getProfileFromObjectInfo(logic and logic.getSelectedBuildObject and logic:getSelectedBuildObject() or nil) end
local function glazed(profile) local mats=profile and profile.definition and profile.definition.engineMaterials or {}; for _,v in ipairs(mats or {}) do if v=="Glass" then return true end end; return false end
function GarageBuild.getRequirements(profile,length)
    if not profile then return nil end; length=GarageBuild.normalizeLength(length); local steps=math.ceil(length/3)
    local r={BlowTorch={amount=math.min(steps,10),uses=true},Bars={amount=length},Hinge={amount=length*2},WeldingRods={amount=math.min(steps*2,20),uses=true}}
    if glazed(profile) then r.SmallSheetMetal={amount=length*2}; r.GlassPanel={amount=length} else r.SmallSheetMetal={amount=length*3} end
    return r
end
local function keyToType(k) local m={BlowTorch="Base.BlowTorch",SmallSheetMetal="Base.SmallSheetMetal",GlassPanel="Base.GlassPanel",Hinge="Base.Hinge",WeldingRods="Base.WeldingRods"}; return m[k] end
local function add(entry,item,seen) if not item or seen[item] then return end; seen[item]=true; entry.items[#entry.items+1]=item; entry.count=entry.count+1; if instanceof(item,"DrainableComboItem") and item:getCurrentUses()>0 then entry.uses=entry.uses+item:getCurrentUses() end end
local function addContainer(entry,container,fullType,seen)
    if not container or not ISBuildIsoEntity then return end; local items=container:getAllTypeEvalRecurse(fullType,ISBuildIsoEntity.predicateMaterial); if items then for i=0,items:size()-1 do add(entry,items:get(i),seen) end end
end
function GarageBuild.getStock(character,containers)
    local stock={}; local ground=character and ISBuildIsoEntity and ISBuildIsoEntity.GetAllGroundItemsForPlayer(character) or nil
    for _,fullType in ipairs(RESOURCE_TYPES) do local e={count=0,uses=0,items={}}; local seen={}; addContainer(e,character and character:getInventory(),fullType,seen)
        if containers then for i=0,containers:size()-1 do addContainer(e,containers:get(i),fullType,seen) end end
        local ge=ground and ground[fullType] or nil; if ge and ge.items then for _,item in ipairs(ge.items) do add(e,item,seen) end end; stock[fullType]=e
    end
    return stock
end
local function available(stock,key,uses)
    if key=="Bars" then return (stock["Base.MetalBar"].count or 0)+(stock["Base.IronBar"].count or 0) end
    local e=stock[keyToType(key)]; return e and (uses and e.uses or e.count) or 0
end
function GarageBuild.hasRequirements(character,profile,length,containers)
    local req=GarageBuild.getRequirements(profile,length); if not req then return true end; local stock=GarageBuild.getStock(character,containers)
    for k,r in pairs(req) do if available(stock,k,r.uses)<r.amount then return false end end; return true
end
function GarageBuild.getAvailable(character,key,uses,containers) return available(GarageBuild.getStock(character,containers),key,uses) end
function GarageBuild.getRequirement(profile,length,fullType)
    local key=({["Base.BlowTorch"]="BlowTorch",["Base.SmallSheetMetal"]="SmallSheetMetal",["Base.GlassPanel"]="GlassPanel",["Base.MetalBar"]="Bars",["Base.IronBar"]="Bars",["Base.Hinge"]="Hinge",["Base.WeldingRods"]="WeldingRods"})[fullType]
    local req=GarageBuild.getRequirements(profile,length); return key and req and req[key] or nil,key
end
local function consume(character,uses,amount,items,record)
    local remaining=amount
    for _,item in ipairs(items or {}) do if remaining<=0 then break end
        if uses then if item and item:getCurrentUses()>0 then remaining=remaining-buildUtil.useDrainable(item,remaining) end
        else local ft=item and item:getFullType() or nil; character:removeFromHands(item); local wo=item and item:getWorldItem() or nil; local sq=wo and wo:getSquare() or nil
            if sq then sq:transmitRemoveItemFromSquare(wo); sq:removeWorldObject(wo); if item:getWorldItem()==wo then item:setWorldItem(nil) end; remaining=remaining-1; record[ft]=(record[ft] or 0)+1
            else local c=item and item:getContainer() or nil; if c then c:Remove(item); remaining=remaining-1; record[ft]=(record[ft] or 0)+1 end end
        end
    end; return remaining
end
function GarageBuild.consumeExtras(character,profile,length,containers,vanillaBarCount)
    local req=GarageBuild.getRequirements(profile,length); if not req then return true end; local base=glazed(profile) and BASE.glazed or BASE.solid; local stock=GarageBuild.getStock(character,containers); local jobs={}
    for k,r in pairs(req) do local amount
        if k=="Bars" then amount=math.max(0,length-math.max(0,tonumber(vanillaBarCount) or 0)) else amount=math.max(0,r.amount-(base[k] or 0)) end
        if amount>0 then if available(stock,k,r.uses)<amount then return false end; jobs[#jobs+1]={key=k,amount=amount,uses=r.uses} end
    end
    local recorded={}
    for _,job in ipairs(jobs) do local items
        if job.key=="Bars" then items={}; for _,ft in ipairs({"Base.MetalBar","Base.IronBar"}) do for _,it in ipairs(stock[ft].items) do items[#items+1]=it end end else items=stock[keyToType(job.key)].items end
        if consume(character,job.uses,job.amount,items,recorded)>0 then return false end
    end
    lastConsumed[character]=recorded; return true
end
function GarageBuild.recordExtras(buildObject)
    local character=buildObject and buildObject.character; local r=character and lastConsumed[character] or nil; if not r or not buildObject.modData then return end; lastConsumed[character]=nil
    for ft,n in pairs(r) do local key="need:"..ft; buildObject.modData[key]=(tonumber(buildObject.modData[key]) or 0)+n end
end
function GarageBuild.createFaceProxy(face,length)
    if not face then return nil end; length=GarageBuild.normalizeLength(length); local w,h=face:getWidth(),face:getHeight(); local horizontal=w>1; if not horizontal and h<=1 then return face end
    local function map(x,y) local axis=horizontal and x or y; local size=horizontal and w or h; local m=axis<=0 and 0 or (axis>=length-1 and size-1 or math.min(1,size-1)); if horizontal then return m,y else return x,m end end
    local p={}; function p:getFaceName() return face:getFaceName() end; function p:getWidth() return horizontal and length or w end; function p:getHeight() return horizontal and h or length end; function p:getzLayers() return face:getzLayers() end
    function p:getMasterX() return face:getMasterX() end; function p:getMasterY() return face:getMasterY() end; function p:getMasterZ() return face:getMasterZ() end; function p:isMasterSet() return face:isMasterSet() end; function p:isMultiSquare() return face:isMultiSquare() end
    function p:getMasterTileInfo() return face:getMasterTileInfo() end; function p:getTileInfoForSprite(tile) return face:getTileInfoForSprite(tile) end
    function p:getTileInfo(x,y,z) local a,b=map(x,y); return face:getTileInfo(a,b,z) end; function p:verifyObject(x,y,z,o) local a,b=map(x,y); return face:verifyObject(a,b,z,o) end; return p
end
return GarageBuild
