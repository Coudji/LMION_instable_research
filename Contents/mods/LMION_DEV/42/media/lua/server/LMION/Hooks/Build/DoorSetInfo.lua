require "BuildingObjects/ISBuildIsoEntity"
local SingleTileDoorBuildProfile=require "LMION/Services/Build/SingleTileDoorBuildProfile"
local SingleTileDoorFinalizer=require "LMION/Services/Build/SingleTileDoorFinalizer"
local LargeGateBuildProfile=require "LMION/Services/Build/LargeGateBuildProfile"
local LargeGateFinalizer=require "LMION/Services/Build/LargeGateFinalizer"
local GarageBuildFinalizer=require "LMION/Services/Build/GarageBuildFinalizer"

local function gameScript(buildObject)
 local spriteScript=buildObject and buildObject.objectInfo and buildObject.objectInfo:getScript() or nil
 return spriteScript and spriteScript:getParent() or nil
end
if not ISBuildIsoEntity._lmionV3DoorSetInfoInstalled then
 ISBuildIsoEntity._lmionV3DoorSetInfoInstalled=true
 local previous=ISBuildIsoEntity.setInfo
 ISBuildIsoEntity.setInfo=function(self,square,north,sprite,openSprite)
  local script=gameScript(self)
  local single=SingleTileDoorBuildProfile.getByGameScript(script)
  local large=LargeGateBuildProfile.getByGameScript(script)
  local garage=GarageBuildFinalizer.getProfile(self)
  if garage and not GarageBuildFinalizer.beforeSetInfo(self,garage) then error("LMION Garage extra-resource consumption failed") end
  local result=previous(self,square,north,sprite,openSprite)
  if single then SingleTileDoorFinalizer.finalize(square,single,self.craftRecipe,self.character)
  elseif large then LargeGateFinalizer.finalize(square,large,self.craftRecipe,self.character)
  elseif garage then GarageBuildFinalizer.finalize(self,square,garage) end
  return result
 end
 print("[LMION:DEV] shared door Build setInfo hook installed")
end
