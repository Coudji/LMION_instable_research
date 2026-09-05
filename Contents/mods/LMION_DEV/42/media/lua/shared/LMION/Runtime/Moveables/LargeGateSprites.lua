local LargeGateProfiles = require "LMION/Services/Moveables/LargeGateProfiles"

local LargeGateSprites = {}

function LargeGateSprites.configure()
    LargeGateProfiles.invalidate()

    local definitionIds = LargeGateProfiles.getDefinitionIds()
    local configured = 0

    for definitionIndex = 1, #definitionIds do
        local profile = LargeGateProfiles.getByDefinitionId(definitionIds[definitionIndex])
        for _, facing in ipairs({ "N", "W" }) do
            for _, leaf in ipairs({ "A", "B" }) do
                local parts = profile.geometry[facing][leaf]
                for partIndex = 1, 2 do
                    for _, spriteName in ipairs({ parts[partIndex].closed, parts[partIndex].open }) do
                        local sprite = getSprite(spriteName)
                        local properties = sprite and sprite:getProperties() or nil
                        if properties ~= nil then
                            properties:set("IsMoveAble")
                            configured = configured + 1
                        end
                    end
                end
            end
        end
    end

    print(string.format(
        "[LMION:DEV] LargeGate Moveables sprites configured: %d sprites for %d definitions",
        configured,
        #definitionIds
    ))

    return configured
end

return LargeGateSprites
