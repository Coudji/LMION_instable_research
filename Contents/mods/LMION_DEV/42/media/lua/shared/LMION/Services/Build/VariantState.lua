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
    local recipe = getRecipe(logic)
    local group = VariantGroups.getForRecipe(recipe)
    if group == nil or #group.members == 0 then
        return nil
    end

    local definitionId = VariantGroups.getDefinitionIdForRecipe(recipe)
    local member = definitionId
        and group.memberByDefinitionId[definitionId]
        or nil

    return member or group.representative
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

    local recipe = VariantGroups.getRecipeForMember(member)
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
