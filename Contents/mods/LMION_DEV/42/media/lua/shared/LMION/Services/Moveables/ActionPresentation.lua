local Resolver = require "LMION/Definitions/Resolver"
local ActionContract = require "LMION/Services/Moveables/ActionContract"

local ActionPresentation = {}

function ActionPresentation.resolve(moveProps, mode)
    if moveProps == nil
        or type(moveProps.lmionDefinitionId) ~= "string"
        or (mode ~= "pickup" and mode ~= "place") then
        return nil
    end

    local definition = Resolver.resolveDefinition(moveProps.lmionDefinitionId)
    local action = ActionContract.get(definition, mode)
    if action == nil then
        return nil
    end

    return {
        definitionId = moveProps.lmionDefinitionId,
        mode = mode,
        animation = action.animation,
        sound = action.sound,
    }
end

return ActionPresentation
