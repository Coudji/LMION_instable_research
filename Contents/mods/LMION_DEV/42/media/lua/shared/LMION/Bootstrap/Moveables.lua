local SingleTileDoorHook = require "LMION/Hooks/Moveables/SingleTileDoor"
local GaragePickupHook = require "LMION/Hooks/Moveables/GaragePickup"
local LargeGateFacingHook = require "LMION/Hooks/Moveables/LargeGateFacing"
local LargeGatePickupHook = require "LMION/Hooks/Moveables/LargeGatePickup"
local LargeGatePlacementHook = require "LMION/Hooks/Moveables/LargeGatePlacement"
local SingleTileDoorSprites = require "LMION/Runtime/Moveables/SingleTileDoorSprites"
local GarageSpriteGrids = require "LMION/Runtime/Moveables/GarageSpriteGrids"
local LargeGateSprites = require "LMION/Runtime/Moveables/LargeGateSprites"
local LargeGateSpriteGrids = require "LMION/Runtime/Moveables/LargeGateSpriteGrids"
local ToolDefinitions = require "LMION/Runtime/Moveables/ToolDefinitions"

local MoveablesBootstrap = {}
local hasRun = false

local function configureSprites()
    SingleTileDoorSprites.configure()
    GarageSpriteGrids.configure()
    LargeGateSprites.configure()
    LargeGateSpriteGrids.configure()
end

function MoveablesBootstrap.run()
    if hasRun then return false end
    hasRun = true
    ToolDefinitions.install()
    SingleTileDoorHook.install()
    GaragePickupHook.install()
    LargeGateFacingHook.install()
    LargeGatePickupHook.install()
    LargeGatePlacementHook.install()
    if Events ~= nil and Events.OnLoadedTileDefinitions ~= nil then Events.OnLoadedTileDefinitions.Add(configureSprites) end
    return true
end
return MoveablesBootstrap
