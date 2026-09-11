require "BuildingObjects/ISBuildIsoEntity"
local GarageBuild=require "LMION/Services/Build/GarageLengthState"
local function profile(self) return self and self.objectInfo and GarageBuild.getProfileFromObjectInfo(self.objectInfo) or nil end
local function length(self) return GarageBuild.normalizeLength(tonumber(self and self.lmionGarageLength) or GarageBuild.getLengthFromLogic(self and self.buildPanelLogic)) end
local function containers(self) local l=self and self.buildPanelLogic;return l and l.getContainers and l:getContainers() or (self and self.containers or nil) end
if not ISBuildIsoEntity._lmionV3GarageBuildInstalled then
 ISBuildIsoEntity._lmionV3GarageBuildInstalled=true
 local previousNew=ISBuildIsoEntity.new;local previousFace=ISBuildIsoEntity.getFace;local previousValid=ISBuildIsoEntity.isValid;local previousCreate=ISBuildIsoEntity.create
 ISBuildIsoEntity.new=function(self,character,objectInfo,nSprite,containersArg,logic,lmionGarageLength)
  local o=previousNew(self,character,objectInfo,nSprite,containersArg,logic);local p=GarageBuild.getProfileFromObjectInfo(objectInfo);if p then o.lmionGarageLength=GarageBuild.normalizeLength(lmionGarageLength or (logic and GarageBuild.getLengthFromLogic(logic)) or 3) end;return o
 end
 ISBuildIsoEntity.getFace=function(self)
  local face=previousFace(self);if not profile(self) or not face then return face end;local l=length(self);if self._lmionGarageFaceSource~=face or self._lmionGarageFaceLength~=l then self._lmionGarageFaceSource=face;self._lmionGarageFaceLength=l;self._lmionGarageFaceProxy=GarageBuild.createFaceProxy(face,l) end;return self._lmionGarageFaceProxy
 end
 ISBuildIsoEntity.isValid=function(self,square)
  if not previousValid(self,square) then return false end;local p=profile(self);if not p or self.character:isBuildCheat() then return true end;return GarageBuild.hasRequirements(self.character,p,length(self),containers(self))
 end
 ISBuildIsoEntity.create=function(self,x,y,z,north,sprite)
  local p=profile(self);if p and not self.character:isBuildCheat() and not GarageBuild.hasRequirements(self.character,p,length(self),containers(self)) then return false end;self._lmionGarageExtrasConsumed=false;return previousCreate(self,x,y,z,north,sprite)
 end
 print("[LMION:DEV] variable Garage Build cursor hook installed")
end
