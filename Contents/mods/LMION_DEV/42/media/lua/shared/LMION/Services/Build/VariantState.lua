local VariantGroups = require "LMION/Services/Build/VariantGroups"

local VariantState = {}
local selectionByLogic = setmetatable({}, { __mode = "k" })

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
    local group = VariantState.getGroupFromLogic(logic)
    if group == nil or #group.members == 0 then
        return nil
    end

    local definitionId = selectionByLogic[logic]
    local member = definitionId
        and group.memberByDefinitionId[definitionId]
        or nil

    if member == nil then
        member = group.representative
        selectionByLogic[logic] = member.definitionId
    end

    return member
end

function VariantState.setSelectedDefinitionId(logic, definitionId)
    local group = VariantState.getGroupFromLogic(logic)
    if group == nil then
        return nil
    end

    local member = group.memberByDefinitionId[definitionId]
    if member == nil then
        return nil
    end

    selectionByLogic[logic] = member.definitionId
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

    local member = group.members[index]
    selectionByLogic[logic] = member.definitionId
    return member
end

return VariantState
