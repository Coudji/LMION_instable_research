local originalOpenMovableCursor = nil

local function install()
    if type(ISMoveableContextMenu) ~= "table"
        or type(ISMoveableContextMenu.openMovableCursor) ~= "function" then
        return
    end

    if originalOpenMovableCursor == nil then
        originalOpenMovableCursor = ISMoveableContextMenu.openMovableCursor
    end

    if ISMoveableContextMenu.openMovableCursor == LMIONInventoryOpenMovableCursor then
        return
    end

    LMIONInventoryOpenMovableCursor = function(item, playerObj)
        local modData = item and item.getModData and item:getModData() or nil

        if type(LMIONOpenGaragePlacementCursor) == "function"
            and modData ~= nil
            and modData.lmionGarageDefinitionId ~= nil
            and LMIONOpenGaragePlacementCursor(item, playerObj) then
            return
        end

        if type(LMIONOpenDoorInventoryPlacementCursor) == "function"
            and LMIONOpenDoorInventoryPlacementCursor(item, playerObj) then
            return
        end

        return originalOpenMovableCursor(item, playerObj)
    end

    ISMoveableContextMenu.openMovableCursor = LMIONInventoryOpenMovableCursor
end

install()
Events.OnGameStart.Add(install)
