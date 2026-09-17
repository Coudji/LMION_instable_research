local LMION = require "LMION/API"
local DefinitionBootstrap = require "LMION/Bootstrap/Definitions"
local MoveablesBootstrap = require "LMION/Bootstrap/Moveables"
local DefinitionIndexDiagnostics = require "LMION/Diagnostics/DefinitionIndex"
local LargeGateBuildDiagnostics = require "LMION/Diagnostics/LargeGateBuild"
local VanillaLargeGateLeafPreparation = require "LMION/Runtime/Build/VanillaLargeGateLeafPreparation"
local CraftRecipeHydrator = require "LMION/Runtime/Build/CraftRecipeHydrator"

DefinitionBootstrap.run(LMION)
MoveablesBootstrap.run()
VanillaLargeGateLeafPreparation.install()

local SERVICE_DOOR_DEFINITIONS = {
    "Doors.Metal.BlackServiceDoor",
    "Doors.Metal.BlueServiceDoor",
    "Doors.Metal.GreenServiceDoor",
    "Doors.Metal.LightRedServiceDoor",
    "Doors.Metal.OrangeServiceDoor",
    "Doors.Metal.RedServiceDoor",
    "Doors.Metal.WhiteServiceDoorWithPorthole",
}

for index = 1, #SERVICE_DOOR_DEFINITIONS do
    CraftRecipeHydrator.hydrateDefinition(SERVICE_DOOR_DEFINITIONS[index])
end

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
