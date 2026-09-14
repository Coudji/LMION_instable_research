local originalOpenMovableCursor = nil

local function install()
    if type(ISMoveableContextMenu) ~= "table"
        or type(ISMoveableContextMenu.openMovableCursor) ~= "function"
        or type(LMIONOpenGaragePlacementCursor) ~= "function" then
        return
    end

    if originalOpenMovableCursor == nil then
        originalOpenMovableCursor = ISMoveableContextMenu.openMovableCursor
    end

    if ISMoveableContextMenu.openMovableCursor == LMIONGarageOpenMovableCursor then
        return
    end

    LMIONGarageOpenMovableCursor = function(item, playerObj)
        local modData = item and item.getModData and item:getModData() or nil

        if modData ~= nil
            and modData.lmionGarageDefinitionId ~= nil
            and LMIONOpenGaragePlacementCursor(item, playerObj) then
            return
        end

        return originalOpenMovableCursor(item, playerObj)
    end

    ISMoveableContextMenu.openMovableCursor = LMIONGarageOpenMovableCursor
end

install()
Events.OnGameStart.Add(install)
