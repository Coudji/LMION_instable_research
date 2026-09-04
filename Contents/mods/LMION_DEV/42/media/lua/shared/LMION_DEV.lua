local LMION = require "LMION/API"
local DefinitionBootstrap = require "LMION/Bootstrap/Definitions"

DefinitionBootstrap.run(LMION)

local stats = LMION.getRegistrationStats()
print(string.format(
    "[LMION:DEV] definitions ready: %d defaults, %d definitions, %d extensions",
    stats.defaults,
    stats.definitions,
    stats.extensions
))
