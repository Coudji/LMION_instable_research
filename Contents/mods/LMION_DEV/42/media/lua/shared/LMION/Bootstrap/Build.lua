local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeHydrator = require "LMION/Runtime/Build/CraftRecipeHydrator"
local GarageCraftRecipeHydrator = require "LMION/Runtime/Build/Garage/CraftRecipeHydrator"
local LargeGateCraftRecipeHydrator = require "LMION/Runtime/Build/LargeGate/CraftRecipeHydrator"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"
local MenuFilter = require "LMION/Runtime/Build/MenuFilter"
local DefinitionMembers = require "LMION/Services/Build/DefinitionMembers"

local BuildBootstrap = {}
local hasRun = false
local listenerInstalled = false
local hydratedRevision = -1

local function hydrateDefinition(definitionId, definition, entityId)
    if definition.doorType == "Garage" then
        GarageCraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
        return
    end

    if definition.doorType == "LargeGate" then
        LargeGateCraftRecipeHydrator.hydrateDefinition(
            definitionId,
            entityId
        )
        return
    end

    CraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
end

function BuildBootstrap.refresh(force)
    local revision = Registry.getRevision()
    if not force and hydratedRevision == revision then
        return false
    end

    local definitionIds = Registry.getDefinitionIds()

    for index = 1, #definitionIds do
        local definitionId = definitionIds[index]
        local definition = Resolver.resolveDefinition(definitionId)
        local construction = type(definition) == "table"
            and definition.construction
            or nil

        if type(construction) == "table" then
            local members = DefinitionMembers.get(definition)
            for memberIndex = 1, #members do
                local entityId = members[memberIndex].entityId
                local recipe = BuildRecipe.getByEntityId(entityId)

                if recipe ~= nil then
                    hydrateDefinition(definitionId, definition, entityId)
                end
            end
        end
    end

    hydratedRevision = revision
    return true
end

local function refreshSafely()
    if not hasRun then
        return
    end

    local ok, reason = pcall(BuildBootstrap.refresh, true)
    if not ok then
        print(
            "[LMION:DEV] Build definition projection deferred: "
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

function BuildBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true

    MenuFilter.install()
    VanillaLargeGateLeafPreparation.install()
    installRegistryListener()
    BuildBootstrap.refresh(true)

    if Events ~= nil and Events.OnGameBoot ~= nil then
        Events.OnGameBoot.Add(refreshSafely)
    end

    return true
end

return BuildBootstrap
