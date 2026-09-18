require "Moveables/ISMoveableDefinitions"

local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local ItemSelector = require "LMION/PZ/ItemSelector"
local ActionContract = require "LMION/Services/Moveables/ActionContract"

local ToolDefinitions = {}
local installed = false
local listenerInstalled = false
local registeredNames = {}
local builtRevision = -1

local function fail(message)
    error("LMION Moveables ToolDefinitions: " .. message, 3)
end

local function getPerk(skillName)
    if skillName == nil then
        return nil
    end

    if PerkFactory == nil
        or PerkFactory.Perks == nil
        or PerkFactory.Perks.FromString == nil then
        fail("PerkFactory.Perks.FromString is unavailable")
    end

    local perk = PerkFactory.Perks.FromString(skillName)
    if perk == nil then
        fail("unknown Moveables skill " .. tostring(skillName))
    end
    return perk
end

local function registerAction(definitions, definition, mode)
    local action = ActionContract.get(definition, mode)
    if action == nil or action.toolSelector == nil then
        return
    end

    local itemTypes = ItemSelector.getItemTypes(action.toolSelector)
    if #itemTypes == 0 then
        fail(
            "tool selector resolved no items for "
                .. tostring(definition.definitionId)
                .. " "
                .. mode
        )
    end

    local name = action.toolDefinitionName
    definitions.removeToolDefinition(name)
    definitions.addToolDefinition(
        name,
        itemTypes,
        getPerk(action.skillName),
        action.time,
        action.sound,
        action.soundIsWav
    )
    registeredNames[name] = true
end

function ToolDefinitions.refresh(force)
    local revision = Registry.getRevision()
    if not force and builtRevision == revision then
        return false
    end

    local definitions = ISMoveableDefinitions:getInstance()
    for name in pairs(registeredNames) do
        definitions.removeToolDefinition(name)
    end
    registeredNames = {}
    ItemSelector.clearCache()

    for _, definitionId in ipairs(Registry.getDefinitionIds()) do
        local definition = Resolver.resolveDefinition(definitionId)
        registerAction(definitions, definition, "pickup")
        registerAction(definitions, definition, "place")
    end

    builtRevision = revision
    return true
end

local function refreshSafely()
    if not installed then
        return
    end

    local ok, reason = pcall(ToolDefinitions.refresh, true)
    if not ok then
        print(
            "[LMION:DEV] Moveables tool projection deferred: "
                .. tostring(reason)
        )
    end
end

local function installRegistryListener()
    if listenerInstalled then
        return
    end

    listenerInstalled = true
    Registry.addChangeListener(refreshSafely)
end

function ToolDefinitions.install()
    if installed then
        return false
    end
    installed = true

    installRegistryListener()
    refreshSafely()

    if Events ~= nil and Events.OnGameBoot ~= nil then
        Events.OnGameBoot.Add(refreshSafely)
    end

    return true
end

return ToolDefinitions
