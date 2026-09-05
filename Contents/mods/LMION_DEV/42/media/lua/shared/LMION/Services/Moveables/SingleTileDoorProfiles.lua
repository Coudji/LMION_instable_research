local PairedDoorProfiles = require "LMION/Services/Moveables/PairedDoorProfiles"
local SingleEntityDoorProfiles = require "LMION/Services/Moveables/SingleEntityDoorProfiles"

local SingleTileDoorProfiles = {}

local providers = {
    SingleEntityDoorProfiles,
    PairedDoorProfiles,
}

function SingleTileDoorProfiles.invalidate()
    for index = 1, #providers do
        providers[index].invalidate()
    end
end

function SingleTileDoorProfiles.getBySprite(sprite)
    for index = 1, #providers do
        local profile = providers[index].getBySprite(sprite)
        if profile ~= nil then
            return profile
        end
    end

    return nil
end

function SingleTileDoorProfiles.getConfiguredSpriteNames()
    local seen = {}
    local names = {}

    for index = 1, #providers do
        local providerNames = providers[index].getConfiguredSpriteNames()
        for nameIndex = 1, #providerNames do
            local spriteName = providerNames[nameIndex]
            if not seen[spriteName] then
                seen[spriteName] = true
                names[#names + 1] = spriteName
            end
        end
    end

    return names
end

return SingleTileDoorProfiles
