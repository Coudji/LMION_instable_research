local Resolver = require "LMION/Definitions/Resolver"

local ActionPresentation = {}

local TOOL_KIND_BY_TAG = {
    ["base:screwdriver"] = "screwdriver",
    ["base:crowbar"] = "crowbar",
    ["base:hammer"] = "hammer",
}

-- Keep presentation sounds in one place. The definition remains authoritative
-- for the required tool and skill; this table only maps that semantic contract
-- to PZ presentation assets.
local SOUNDS = {
    crowbar = {
        Woodwork = "BeginRemoveBarricadePlankCrowbar",
        MetalWelding = "BreakMetalItem",
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

    -- Replacement currently inherits the pickup skill contract. Supporting an
    -- explicit replacement.skill as well keeps the presentation policy future
    -- proof without changing the current public schema.
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
        return "Build"
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
