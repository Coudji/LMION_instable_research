local DoorObject = require "LMION/PZ/DoorObject"
local CommonLargeGateProfiles = require "LMION/Services/Common/LargeGate/Profiles"
local WorldObjectIdentity = require "LMION/PZ/WorldObjectIdentity"

local BuiltLargeGatePart = {}

function BuiltLargeGatePart.find(square, entityId, leaf)
    if square == nil or type(entityId) ~= "string" then
        return nil, nil
    end

    local specialObjects = square:getSpecialObjects()
    for index = specialObjects:size() - 1, 0, -1 do
        local object = specialObjects:get(index)
        if DoorObject.isDoor(object)
            and WorldObjectIdentity.getEntityId(object) == entityId then
            local sprite = object:getSprite()
            local segment = CommonLargeGateProfiles.getSegmentBySprite(sprite)
            if segment ~= nil and segment.leaf == leaf then
                return object, segment
            end
        end
    end

    return nil, nil
end

return BuiltLargeGatePart
