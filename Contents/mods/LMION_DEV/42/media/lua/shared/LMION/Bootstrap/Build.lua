local CraftRecipeHydrator = require "LMION/Runtime/Build/CraftRecipeHydrator"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"
local VariantMenuFilter = require "LMION/Runtime/Build/VariantMenuFilter"

local BuildBootstrap = {}
local hasRun = false

local DEFINITION_OWNED_RECIPES = {
    "Doors.Metal.BlackServiceDoor",
    "Doors.Metal.BlueServiceDoor",
    "Doors.Metal.GreenServiceDoor",
    "Doors.Metal.LightRedServiceDoor",
    "Doors.Metal.OrangeServiceDoor",
    "Doors.Metal.RedServiceDoor",
    "Doors.Metal.WhiteServiceDoorWithPorthole",
}

local function hydrateDefinitionOwnedRecipes()
    for index = 1, #DEFINITION_OWNED_RECIPES do
        CraftRecipeHydrator.hydrateDefinition(
            DEFINITION_OWNED_RECIPES[index]
        )
    end
end

function BuildBootstrap.run()
    if hasRun then
        return false
    end

    hasRun = true

    VariantMenuFilter.install()
    VanillaLargeGateLeafPreparation.install()
    hydrateDefinitionOwnedRecipes()

    return true
end

return BuildBootstrap
