local LargeGateEntityNames = require "LMION/Runtime/Build/LargeGateEntityNames"
local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"

local LargeGateBuild = {}

local function hasBuildComponents(entityId)
    local script = ScriptManager.instance:getGameEntityScript(entityId)
    if script == nil then
        return false
    end

    return script:getComponentScriptFor(ComponentType.SpriteConfig) ~= nil
        and script:getComponentScriptFor(ComponentType.CraftRecipe) ~= nil
end

function LargeGateBuild.run()
    if ScriptManager == nil or ScriptManager.instance == nil or ComponentType == nil then
        return
    end

    local expected = 0
    local ready = 0
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definition = Resolver.resolveDefinition(definitionIds[index])
        if definition ~= nil and definition.doorType == "LargeGate" then
            for _, leaf in ipairs({ "A", "B" }) do
                expected = expected + 1
                local entityId = LargeGateEntityNames.getLeafEntityId(definition, leaf)
                if entityId ~= nil and hasBuildComponents(entityId) then
                    ready = ready + 1
                else
                    print(string.format(
                        "[LMION:DEV] LargeGate Build bridge missing: definition=%s leaf=%s entity=%s",
                        tostring(definition.definitionId),
                        tostring(leaf),
                        tostring(entityId)
                    ))
                end
            end
        end
    end

    print(string.format(
        "[LMION:DEV] LargeGate Build bridge ready: %d/%d leaf entities",
        ready,
        expected
    ))
end

return LargeGateBuild
