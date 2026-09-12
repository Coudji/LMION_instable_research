local LMION = require "LMION/API"
local DefinitionBootstrap = require "LMION/Bootstrap/Definitions"
local MoveablesBootstrap = require "LMION/Bootstrap/Moveables"
local DefinitionIndexDiagnostics = require "LMION/Diagnostics/DefinitionIndex"
local LargeGateBuildDiagnostics = require "LMION/Diagnostics/LargeGateBuild"
local DoorScriptProjection = require "LMION/Runtime/Build/DoorScriptProjection"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"

DefinitionBootstrap.run(LMION)
MoveablesBootstrap.run()

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(function()
        VanillaLargeGateLeafPreparation.prepare()
        DoorScriptProjection.apply()
        LargeGateBuildDiagnostics.run()
    end)
end

local stats = LMION.getRegistrationStats()
print(string.format(
    "[LMION:DEV] definitions ready: %d defaults, %d definitions, %d extensions",
    stats.defaults,
    stats.definitions,
    stats.extensions
))

DefinitionIndexDiagnostics.run()
