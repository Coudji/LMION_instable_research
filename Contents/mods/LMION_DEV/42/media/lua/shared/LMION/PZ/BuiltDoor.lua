local DoorObject = require "LMION/PZ/DoorObject"
local WorldObjectIdentity = require "LMION/PZ/WorldObjectIdentity"

local BuiltDoor = {}

function BuiltDoor.findByEntityId(square, entityId)
    if square == nil or type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    local specialObjects = square:getSpecialObjects()
    for index = specialObjects:size() - 1, 0, -1 do
        local object = specialObjects:get(index)
        if DoorObject.isDoor(object) then
            local objectEntityId = WorldObjectIdentity.getEntityId(object)
            if objectEntityId == entityId then
                return object
            end
        end
    end

    return nil
end

return BuiltDoor
