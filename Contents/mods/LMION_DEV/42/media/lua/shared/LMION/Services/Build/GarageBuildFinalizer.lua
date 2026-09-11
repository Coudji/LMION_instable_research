local GarageBuild=require "LMION/Services/Build/GarageLengthState"
local SingleTileDoorFinalizer=require "LMION/Services/Build/SingleTileDoorFinalizer"
local GarageBuildFinalizer={}

local function containers(buildObject)
 local logic=buildObject and buildObject.buildPanelLogic or nil
 return logic and logic.getContainers and logic:getContainers() or (buildObject and buildObject.containers or nil)
end
local function length(buildObject)
 return GarageBuild.normalizeLength(tonumber(buildObject and buildObject.lmionGarageLength) or GarageBuild.getLengthFromLogic(buildObject and buildObject.buildPanelLogic))
end
local function vanillaBars(buildObject)
 local data=buildObject and buildObject.modData or nil
 return (tonumber(data and data["need:Base.MetalBar"]) or 0)+(tonumber(data and data["need:Base.IronBar"]) or 0)
end
function GarageBuildFinalizer.getProfile(buildObject)
 return buildObject and buildObject.objectInfo and GarageBuild.getProfileFromObjectInfo(buildObject.objectInfo) or nil
end
function GarageBuildFinalizer.beforeSetInfo(buildObject,profile)
 if profile==nil or buildObject.character:isBuildCheat() or buildObject._lmionGarageExtrasConsumed then return true end
 if not GarageBuild.consumeExtras(buildObject.character,profile,length(buildObject),containers(buildObject),vanillaBars(buildObject)) then return false end
 GarageBuild.recordExtras(buildObject);buildObject._lmionGarageExtrasConsumed=true;return true
end
function GarageBuildFinalizer.finalize(buildObject,square,profile)
 if profile==nil then return nil end
 return SingleTileDoorFinalizer.finalize(square,profile,buildObject.craftRecipe,buildObject.character)
end
return GarageBuildFinalizer
