require "BuildingObjects/ISBuildIsoEntity"
local SingleTileDoorBuildProfile=require "LMION/Services/Build/SingleTileDoorBuildProfile"
local SingleTileDoorPlacement=require "LMION/Services/Moveables/SingleTileDoorPlacement"
local MOD_ID="LMION_DEV"
local function gameScript(buildObject) local spriteScript=buildObject and buildObject.objectInfo and buildObject.objectInfo:getScript() or nil;return spriteScript and spriteScript:getParent() or nil end
local function profile(buildObject)
 if buildObject==nil or buildObject.craftRecipe==nil then return nil end
 if buildObject.craftRecipe.getModID and buildObject.craftRecipe:getModID()~=MOD_ID then return nil end
 return SingleTileDoorBuildProfile.getByGameScript(gameScript(buildObject))
end
local function facing(buildObject) return buildObject.north==true and "N" or "W" end
local function valid(buildObject,square) local p=profile(buildObject);return p==nil or SingleTileDoorPlacement.canPlace(p,square,facing(buildObject)) end
if not ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled then
 ISBuildIsoEntity._lmionV3SingleTileDoorBuildInstalled=true
 local previousValid=ISBuildIsoEntity.isValid;local previousPerSquare=ISBuildIsoEntity.isValidPerSquare
 ISBuildIsoEntity.isValid=function(self,square) return previousValid(self,square) and valid(self,square) end
 ISBuildIsoEntity.isValidPerSquare=function(self,square,tileInfo,requiresFloor,extendsN,extendsW) return previousPerSquare(self,square,tileInfo,requiresFloor,extendsN,extendsW) and valid(self,square) end
 print("[LMION:DEV] Single-tile Build validation hook installed")
end
