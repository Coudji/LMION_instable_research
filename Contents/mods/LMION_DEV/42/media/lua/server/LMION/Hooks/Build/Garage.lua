require "BuildingObjects/ISBuildIsoEntity"
local GarageBuild=require "LMION/Services/Build/GarageLengthState"
local SingleTileDoorFinalizer=require "LMION/Services/Build/SingleTileDoorFinalizer"

local function profile(self) return self and self.objectInfo and GarageBuild.getProfileFromObjectInfo(self.objectInfo) or nil end
local function length(self) return GarageBuild.normalizeLength(tonumber(self and self.lmionGarageLength) or GarageBuild.getLengthFromLogic(self and self.buildPanelLogic)) end
local function containers(self) local l=self and self.buildPanelLogic; return l and l.getContainers and l:getContainers() or (self and self.containers or nil) end
local function bars(self) local md=self and self.modData or {}; return (tonumber(md["need:Base.MetalBar"]) or 0)+(tonumber(md["need:Base.IronBar"]) or 0) end

if not ISBuildIsoEntity._lmionV3GarageBuildInstalled then
 ISBuildIsoEntity._lmionV3GarageBuildInstalled=true
 local prevNew=ISBuildIsoEntity.new; local prevFace=ISBuildIsoEntity.getFace; local prevValid=ISBuildIsoEntity.isValid; local prevCreate=ISBuildIsoEntity.create; local prevSet=ISBuildIsoEntity.setInfo
 ISBuildIsoEntity.new=function(self,character,objectInfo,nSprite,containersArg,logic,lmionGarageLength)
    local o=prevNew(self,character,objectInfo,nSprite,containersArg,logic); local p=GarageBuild.getProfileFromObjectInfo(objectInfo); if p then o.lmionGarageLength=GarageBuild.normalizeLength(lmionGarageLength or (logic and GarageBuild.getLengthFromLogic(logic)) or 3) end; return o
 end
 ISBuildIsoEntity.getFace=function(self)
    local f=prevFace(self); if not profile(self) or not f then return f end; local len=length(self); if self._lmionGarageFaceSource~=f or self._lmionGarageFaceLength~=len then self._lmionGarageFaceSource=f; self._lmionGarageFaceLength=len; self._lmionGarageFaceProxy=GarageBuild.createFaceProxy(f,len) end; return self._lmionGarageFaceProxy
 end
 ISBuildIsoEntity.isValid=function(self,square)
    if not prevValid(self,square) then return false end; local p=profile(self); if not p or self.character:isBuildCheat() then return true end; return GarageBuild.hasRequirements(self.character,p,length(self),containers(self))
 end
 ISBuildIsoEntity.create=function(self,x,y,z,north,sprite)
    local p=profile(self); if p and not self.character:isBuildCheat() and not GarageBuild.hasRequirements(self.character,p,length(self),containers(self)) then return false end; self._lmionGarageExtrasConsumed=false; return prevCreate(self,x,y,z,north,sprite)
 end
 ISBuildIsoEntity.setInfo=function(self,square,north,sprite,openSprite)
    local p=profile(self); if p and not self.character:isBuildCheat() and not self._lmionGarageExtrasConsumed then if not GarageBuild.consumeExtras(self.character,p,length(self),containers(self),bars(self)) then error("LMION Garage extra-resource consumption failed") end; GarageBuild.recordExtras(self); self._lmionGarageExtrasConsumed=true end
    local result=prevSet(self,square,north,sprite,openSprite); if p then SingleTileDoorFinalizer.finalize(square,p,self.craftRecipe,self.character) end; return result
 end
 print("[LMION:DEV] variable Garage Build hook installed")
end
