local BuildRecipe = require "LMION/PZ/BuildRecipe"
local VariantGroups = require "LMION/Services/Build/VariantGroups"

local VariantState = {}

local function getRecipe(logic)
    if logic == nil or logic.getRecipe == nil then
        return nil
    end

    return logic:getRecipe()
end

function VariantState.getGroupFromLogic(logic)
    return VariantGroups.getForRecipe(getRecipe(logic))
end

function VariantState.getSelectedMember(logic)
    return VariantGroups.getMemberForRecipe(getRecipe(logic))
end

function VariantState.setSelectedDefinitionId(logic, definitionId)
    local group = VariantState.getGroupFromLogic(logic)
        or VariantGroups.getForDefinition(definitionId)
    if group == nil then
        return nil
    end

    local member = group.memberByDefinitionId[definitionId]
    if member == nil then
        return nil
    end

    local recipe = BuildRecipe.getByEntityId(member.entityId)
    if recipe == nil or logic == nil or logic.setRecipe == nil then
        return nil
    end

    logic:setRecipe(recipe)
    return member
end

function VariantState.selectRelative(logic, delta)
    local group = VariantState.getGroupFromLogic(logic)
    local current = VariantState.getSelectedMember(logic)

    if group == nil or current == nil or #group.members < 2 then
        return current
    end

    local index = current.index + (tonumber(delta) or 0)
    while index < 1 do
        index = index + #group.members
    end
    while index > #group.members do
        index = index - #group.members
    end

    return VariantState.setSelectedDefinitionId(
        logic,
        group.members[index].definitionId
    )
end

return VariantState
