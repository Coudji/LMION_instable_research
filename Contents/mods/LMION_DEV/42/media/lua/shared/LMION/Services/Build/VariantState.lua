local BuildRecipe = require "LMION/PZ/BuildRecipe"
local VariantAvailability = require "LMION/Services/Build/VariantAvailability"
local VariantGroups = require "LMION/Services/Build/VariantGroups"

local VariantState = {}

local function getRecipe(logic)
    if logic == nil or logic.getRecipe == nil then
        return nil
    end

    return logic:getRecipe()
end

local function setSelectedMember(logic, member, player)
    if member == nil or not VariantAvailability.isAvailable(member, player) then
        return nil
    end

    local recipe = BuildRecipe.getByEntityId(member.entityId)
    if recipe == nil or logic == nil or logic.setRecipe == nil then
        return nil
    end

    logic:setRecipe(recipe)
    return member
end

function VariantState.getGroupFromLogic(logic)
    return VariantGroups.getForRecipe(getRecipe(logic))
end

function VariantState.getSelectedMember(logic)
    return VariantGroups.getMemberForRecipe(getRecipe(logic))
end

function VariantState.getAvailableMembers(logic, player)
    local group = VariantState.getGroupFromLogic(logic)
    return VariantAvailability.getMembers(group, player)
end

function VariantState.setSelectedEntityId(logic, entityId, player)
    local member = VariantGroups.getMemberForEntityId(entityId)
    if member == nil then
        return nil
    end

    local currentGroup = VariantState.getGroupFromLogic(logic)
    if currentGroup ~= nil and currentGroup.key ~= member.group.key then
        return nil
    end

    return setSelectedMember(logic, member, player)
end

function VariantState.setSelectedDefinitionId(logic, definitionId, player)
    local group = VariantState.getGroupFromLogic(logic)
        or VariantGroups.getForDefinition(definitionId)
    if group == nil then
        return nil
    end

    return setSelectedMember(
        logic,
        group.memberByDefinitionId[definitionId],
        player
    )
end

function VariantState.ensureAvailableSelection(logic, player)
    local current = VariantState.getSelectedMember(logic)
    if current ~= nil and VariantAvailability.isAvailable(current, player) then
        return current
    end

    local available = VariantState.getAvailableMembers(logic, player)
    if #available == 0 then
        return nil
    end

    return setSelectedMember(logic, available[1], player)
end

function VariantState.selectRelative(logic, delta, player)
    local group = VariantState.getGroupFromLogic(logic)
    local current = VariantState.getSelectedMember(logic)

    if group == nil then
        return current
    end

    local available = VariantAvailability.getMembers(group, player)
    if #available == 0 then
        return nil
    end
    if #available == 1 then
        return setSelectedMember(logic, available[1], player)
    end

    local currentIndex = nil
    for index = 1, #available do
        if current ~= nil
            and available[index].entityId == current.entityId then
            currentIndex = index
            break
        end
    end

    currentIndex = currentIndex or 1

    local index = currentIndex + (tonumber(delta) or 0)
    while index < 1 do
        index = index + #available
    end
    while index > #available do
        index = index - #available
    end

    return setSelectedMember(logic, available[index], player)
end

return VariantState
