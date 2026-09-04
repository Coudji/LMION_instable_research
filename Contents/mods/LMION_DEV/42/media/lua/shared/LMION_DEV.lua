local LMION = require "LMION/API"
local DefinitionBootstrap = require "LMION/Bootstrap/Definitions"
local MoveablesBootstrap = require "LMION/Bootstrap/Moveables"
local DefinitionIndexDiagnostics = require "LMION/Diagnostics/DefinitionIndex"

DefinitionBootstrap.run(LMION)
MoveablesBootstrap.run()

local stats = LMION.getRegistrationStats()
print(string.format(
    "[LMION:DEV] definitions ready: %d defaults, %d definitions, %d extensions",
    stats.defaults,
    stats.definitions,
    stats.extensions
))

DefinitionIndexDiagnostics.run()
