local SingleTileDoorHook = require "LMION/Hooks/Moveables/SingleTileDoor"
local SingleTileDoorSprites = require "LMION/Runtime/Moveables/SingleTileDoorSprites"
local ToolDefinitions = require "LMION/Runtime/Moveables/ToolDefinitions"

local MoveablesBootstrap = {}

local hasRun = false

local function configureSprites()
    SingleTileDoorSprites.configure()
end

function MoveablesBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true
    ToolDefinitions.install()
    SingleTileDoorHook.install()

    if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then
        Events.OnLoadedTileDefinitions.Add(configureSprites)
    end

    return true
end

return MoveablesBootstrap
