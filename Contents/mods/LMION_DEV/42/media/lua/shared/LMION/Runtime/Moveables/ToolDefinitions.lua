require "Moveables/ISMoveableDefinitions"

local ToolDefinitions = {}

local function register()
    local definitions = ISMoveableDefinitions:getInstance()

    definitions.removeToolDefinition("LMIONMetalScrewdriver")
    definitions.removeToolDefinition("LMIONMetalCrowbar")
    definitions.removeToolDefinition("LMIONMetalHammer")

    definitions.addToolDefinition(
        "LMIONMetalScrewdriver",
        { "Base.Screwdriver" },
        Perks.MetalWelding,
        100,
        "Dismantle",
        true
    )

    definitions.addToolDefinition(
        "LMIONMetalCrowbar",
        { "Tag.Crowbar", "Crowbar" },
        Perks.MetalWelding,
        150,
        "Hammering",
        true
    )

    definitions.addToolDefinition(
        "LMIONMetalHammer",
        { "Base.Hammer" },
        Perks.MetalWelding,
        75,
        "Hammering",
        true
    )
end

function ToolDefinitions.install()
    register()

    if Events ~= nil and Events.OnGameBoot ~= nil then
        Events.OnGameBoot.Add(register)
    end
end

return ToolDefinitions
