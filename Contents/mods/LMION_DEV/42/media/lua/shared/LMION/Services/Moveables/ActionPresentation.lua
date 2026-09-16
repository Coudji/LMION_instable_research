local Resolver = require "LMION/Definitions/Resolver"

local ActionPresentation = {}

local TOOL_KIND_BY_TAG = {
    ["base:screwdriver"] = "screwdriver",
    ["base:crowbar"] = "crowbar",
    ["base:hammer"] = "hammer",
}

-- Definitions own the required tools and skills. This table only translates
-- that semantic contract into PZ presentation assets.
--
-- Screwdriver intentionally has no override: vanilla/configured Moveables sound
-- remains authoritative there. Crowbar and hammer need explicit material-aware
-- presentation because their Moveables tool definitions otherwise both resolve
-- to the generic Hammering sound.
local SOUNDS = {
    crowbar = {
        Woodwork = "BeginRemoveBarricadePlankCrowbar",
        MetalWelding = "BuildMetalStructureSmall",
    },
    hammer = {
        Woodwork = "Hammering",
        MetalWelding = "BuildMetalStructureSmall",
    },
}

local function getToolContract(definition, mode)
    if type(definition) ~= "table" then
        return nil
    end

    local contract = nil
    if mode == "pickup" then
        contract = definition.pickup
    elseif mode == "place" then
        contract = definition.replacement
    end

    if type(contract) ~= "table"
        or type(contract.tools) ~= "table"
        or #contract.tools ~= 1 then
        return nil
    end

    local tool = contract.tools[1]
    local tag = type(tool) == "table" and tool.tag or nil
    if type(tag) ~= "string" or tag == "" then
        return nil
    end

    return {
        tag = string.lower(tag),
        skill = contract.skill,
    }
end

local function getGoverningSkill(definition, contract)
    local skill = contract and contract.skill or nil

    -- Replacement currently shares the pickup skill contract. Accept an
    -- explicit replacement.skill as well so presentation follows the action
    -- contract if the public schema grows later.
    if type(skill) ~= "table" then
        skill = definition and definition.pickup and definition.pickup.skill or nil
    end

    if type(skill) ~= "table" then
        return nil
    end

    if skill.Woodwork ~= nil then
        return "Woodwork"
    end
    if skill.MetalWelding ~= nil then
        return "MetalWelding"
    end

    return nil
end

local function getAnimation(toolKind, mode)
    if toolKind == "screwdriver" then
        return "LMION_ScrewdriverHinge"
    end
    if toolKind == "crowbar" and mode == "pickup" then
        return "LMION_CrowbarPickupLow"
    end
    if toolKind == "hammer" and mode == "place" then
        return "LMION_HammerPlace"
    end

    return nil
end

function ActionPresentation.resolve(moveProps, mode)
    if moveProps == nil
        or type(moveProps.lmionDefinitionId) ~= "string"
        or (mode ~= "pickup" and mode ~= "place") then
        return nil
    end

    local definition = Resolver.resolveDefinition(moveProps.lmionDefinitionId)
    local contract = getToolContract(definition, mode)
    if contract == nil then
        return nil
    end

    local toolKind = TOOL_KIND_BY_TAG[contract.tag]
    if toolKind == nil then
        return nil
    end

    local skillName = getGoverningSkill(definition, contract)
    local soundBySkill = SOUNDS[toolKind]

    return {
        definitionId = moveProps.lmionDefinitionId,
        toolTag = contract.tag,
        toolKind = toolKind,
        skillName = skillName,
        animation = getAnimation(toolKind, mode),
        sound = soundBySkill and soundBySkill[skillName] or nil,
    }
end

return ActionPresentation
