local BuiltinContent = require "LMION/Definitions/BuiltinContent"

local DefinitionBootstrap = {}
local hasRun = false

function DefinitionBootstrap.run(API)
    if hasRun then
        return false
    end

    API.registerContent(BuiltinContent)
    hasRun = true

    return true
end

return DefinitionBootstrap
