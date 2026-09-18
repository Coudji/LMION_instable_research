local Registry = require "LMION/Definitions/Registry"
local Resolver = require "LMION/Definitions/Resolver"
local BuildRecipe = require "LMION/PZ/BuildRecipe"
local CraftRecipeHydrator = require "LMION/Runtime/Build/CraftRecipeHydrator"
local GarageCraftRecipeHydrator = require "LMION/Runtime/Build/Garage/CraftRecipeHydrator"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"
local VariantMenuFilter = require "LMION/Runtime/Build/VariantMenuFilter"

local BuildBootstrap = {}
local hasRun = false
local claimedEntityIds = {}
local hydratedRevision = -1

local function addEntityId(result, seen, entityId)
    if type(entityId) ~= "string" or entityId == "" or seen[entityId] then
        return
    end

    seen[entityId] = true
    result[#result + 1] = entityId
end

local function getDefinitionEntityIds(definition)
    local result = {}
    local seen = {}

    addEntityId(result, seen, definition.entity)

    local entities = definition.entities
    if type(entities) == "table" then
        addEntityId(result, seen, entities.left)
        addEntityId(result, seen, entities.right)

        local extraKeys = {}
        for key, value in pairs(entities) do
            if key ~= "left" and key ~= "right" and type(value) == "string" then
                extraKeys[#extraKeys + 1] = key
            end
        end
        table.sort(extraKeys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        for index = 1, #extraKeys do
            addEntityId(result, seen, entities[extraKeys[index]])
        end
    end

    return result
end

local function hydrateDefinition(definitionId, definition, entityId)
    if definition.doorType == "Garage" then
        GarageCraftRecipeHydrator.hydrateDefinition(definitionId, entityId)
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
            local entityIds = getDefinitionEntityIds(definition)
            for entityIndex = 1, #entityIds do
                local entityId = entityIds[entityIndex]
                local recipe = BuildRecipe.getByEntityId(entityId)

                if recipe ~= nil
                    and (claimedEntityIds[entityId] or BuildRecipe.isEmptyShell(recipe)) then
                    claimedEntityIds[entityId] = true
                    hydrateDefinition(definitionId, definition, entityId)
                end
            end
        end
    end

    hydratedRevision = revision
    return true
end

function BuildBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true

    VariantMenuFilter.install()
    VanillaLargeGateLeafPreparation.install()
    BuildBootstrap.refresh(true)

    if Events ~= nil and Events.OnGameBoot ~= nil then
        Events.OnGameBoot.Add(function()
            BuildBootstrap.refresh(true)
        end)
    end

    return true
end

return BuildBootstrap
