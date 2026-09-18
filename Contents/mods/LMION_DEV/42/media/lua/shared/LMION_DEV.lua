local LMION = require "LMION/API"
local BuildBootstrap = require "LMION/Bootstrap/Build"
local DefinitionBootstrap = require "LMION/Bootstrap/Definitions"
local MoveablesBootstrap = require "LMION/Bootstrap/Moveables"
local DefinitionIndexDiagnostics = require "LMION/Diagnostics/DefinitionIndex"
local LargeGateBuildDiagnostics = require "LMION/Diagnostics/LargeGateBuild"

DefinitionBootstrap.run(LMION)
BuildBootstrap.run()
MoveablesBootstrap.run()

if Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(LargeGateBuildDiagnostics.run)
end

local stats = LMION.getRegistrationStats()
print(string.format(
    "[LMION:DEV] definitions ready: %d defaults, %d definitions, %d extensions",
    stats.defaults,
    stats.definitions,
    stats.extensions
))

DefinitionIndexDiagnostics.run()
