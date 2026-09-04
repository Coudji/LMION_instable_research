local SimpleDoorHook = require "LMION/Hooks/Moveables/SimpleDoor"
local SimpleDoorSprites = require "LMION/Runtime/Moveables/SimpleDoorSprites"

local MoveablesBootstrap = {}

local hasRun = false

local function configureSprites()
    SimpleDoorSprites.configure()
end

function MoveablesBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true
    SimpleDoorHook.install()

    if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
        Events.OnLoadedTileDefinitions.Add(configureSprites)
    end

    return true
end

return MoveablesBootstrap
