local DoorTypes = require "LMION/Domain/DoorTypes"
local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local LargeGateEntityNames = require "LMION/Runtime/Build/LargeGateEntityNames"

local DoorScriptProjection = {}

local function addEntity(plan, entityId, dontNeedFrame, definitionId)
    if type(entityId) ~= "string" or entityId == "" then
        return true
    end

    local existing = plan[entityId]
    if existing ~= nil then
        if existing.dontNeedFrame ~= dontNeedFrame then
            print(string.format(
                "[LMION:DEV] door script projection conflict: entity=%s definition=%s other=%s",
                tostring(entityId),
                tostring(definitionId),
                tostring(existing.definitionId)
            ))
            return false
        end

        return true
    end

    plan[entityId] = {
        definitionId = definitionId,
        dontNeedFrame = dontNeedFrame,
    }

    return true
end

local function addDefinition(plan, definitionId)
    local definition = Resolver.resolveDefinition(definitionId)
    local frameRequirement = DoorTypes.getFrameRequirement(definition.doorType)
    if frameRequirement == nil then
        print(string.format(
            "[LMION:DEV] door script projection skipped: definition=%s reason=unknown-door-type",
            tostring(definitionId)
        ))
        return true
    end

    local dontNeedFrame = frameRequirement == "none"

    if definition.doorType == "LargeGate" then
        local entityA = LargeGateEntityNames.getLeafEntityId(definition, "A")
        local entityB = LargeGateEntityNames.getLeafEntityId(definition, "B")

        return addEntity(plan, entityA, dontNeedFrame, definitionId)
            and addEntity(plan, entityB, dontNeedFrame, definitionId)
    end

    if type(definition.entities) == "table" then
        for _, entityId in pairs(definition.entities) do
            if not addEntity(plan, entityId, dontNeedFrame, definitionId) then
                return false
            end
        end

        return true
    end

    return addEntity(plan, definition.entity, dontNeedFrame, definitionId)
end

local function buildPlan()
    local plan = {}
    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        if not addDefinition(plan, definitionIds[index]) then
            return nil
        end
    end

    return plan
end

local function getScriptName(script, entityId)
    if script ~= nil and script.getName ~= nil then
        local name = script:getName()
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function makePatch(scriptName, dontNeedFrame)
    return string.format([[
entity %s
{
    component SpriteConfig
    {
        dontNeedFrame = %s,
    }
}
]], scriptName, dontNeedFrame and "true" or "false")
end

local function applyEntity(entityId, entry)
    local script = ScriptManager.instance:getGameEntityScript(entityId)
    if script == nil then
        print(string.format(
            "[LMION:DEV] door script projection skipped: entity=%s definition=%s reason=no-script",
            tostring(entityId),
            tostring(entry.definitionId)
        ))
        return false, false
    end

    local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteConfig == nil then
        print(string.format(
            "[LMION:DEV] door script projection skipped: entity=%s definition=%s reason=no-sprite-config",
            tostring(entityId),
            tostring(entry.definitionId)
        ))
        return false, false
    end

    if spriteConfig:getDontNeedFrame() == entry.dontNeedFrame then
        return true, false
    end

    local scriptName = getScriptName(script, entityId)
    local ok, reason = pcall(function()
        -- Deliberately do not call SpriteConfig:PreReload(). This is a narrow
        -- property projection: existing faces, tiles and all other script data
        -- must remain untouched.
        script:Load(
            scriptName,
            makePatch(scriptName, entry.dontNeedFrame)
        )
    end)

    if not ok then
        print(string.format(
            "[LMION:DEV] door script projection failed: entity=%s definition=%s reason=%s",
            tostring(entityId),
            tostring(entry.definitionId),
            tostring(reason)
        ))
        return false, false
    end

    spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteConfig == nil
        or spriteConfig:getDontNeedFrame() ~= entry.dontNeedFrame then
        print(string.format(
            "[LMION:DEV] door script projection failed: entity=%s definition=%s reason=verification",
            tostring(entityId),
            tostring(entry.definitionId)
        ))
        return false, false
    end

    return true, true
end

function DoorScriptProjection.apply()
    if ScriptManager == nil
        or ScriptManager.instance == nil
        or ComponentType == nil then
        return false
    end

    local plan = buildPlan()
    if plan == nil then
        print("[LMION:DEV] door script projection aborted: conflicting entity ownership")
        return false
    end

    local entityIds = {}
    for entityId in pairs(plan) do
        entityIds[#entityIds + 1] = entityId
    end
    table.sort(entityIds)

    local projected = 0
    local unchanged = 0
    local failed = 0

    for index = 1, #entityIds do
        local entityId = entityIds[index]
        local ok, changed = applyEntity(entityId, plan[entityId])

        if not ok then
            failed = failed + 1
        elseif changed then
            projected = projected + 1
        else
            unchanged = unchanged + 1
        end
    end

    print(string.format(
        "[LMION:DEV] door frame projection: projected=%d unchanged=%d failed=%d",
        projected,
        unchanged,
        failed
    ))

    return failed == 0
end

return DoorScriptProjection
