require "PZAPI/ModOptions"
local options=PZAPI.ModOptions:getOptions("LMION_GaragePlacement")
if options==nil then options=PZAPI.ModOptions:create("LMION_GaragePlacement",getText("IGUI_LMION_GarageWidthOptions")) end
if options:getOption("GarageWidthDecrease")==nil then options:addKeyBind("GarageWidthDecrease",getText("IGUI_LMION_GarageWidthDecrease"),Keyboard.KEY_SUBTRACT) end
if options:getOption("GarageWidthIncrease")==nil then options:addKeyBind("GarageWidthIncrease",getText("IGUI_LMION_GarageWidthIncrease"),Keyboard.KEY_ADD) end
local original=nil
local function install()
 if type(ISMoveableContextMenu)~="table" or type(ISMoveableContextMenu.openMovableCursor)~="function" or type(LMIONOpenGaragePlacementCursor)~="function" then return end
 if original==nil then original=ISMoveableContextMenu.openMovableCursor end;if ISMoveableContextMenu.openMovableCursor==LMIONGarageOpenMovableCursor then return end
 LMIONGarageOpenMovableCursor=function(item,playerObj) local data=item and item.getModData and item:getModData() or nil;if data and data.lmionGarageDefinitionId and LMIONOpenGaragePlacementCursor(item,playerObj) then return end;return original(item,playerObj) end
 ISMoveableContextMenu.openMovableCursor=LMIONGarageOpenMovableCursor
end
install();Events.OnGameStart.Add(install)
