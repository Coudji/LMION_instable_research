local GarageBuild = require "LMION/Services/Build/Garage/GarageBuild"

local GarageLengthState = {}
local lengthByLogic = setmetatable({}, { __mode = "k" })

local function getRecipeData(logic)
    if logic == nil or logic.getRecipeData == nil then
        return nil
    end

    return logic:getRecipeData()
end

local function getBarInputData(logic)
    local recipeData = getRecipeData(logic)
    local recipe = recipeData and recipeData.getRecipe and recipeData:getRecipe() or nil
    local inputs = recipe and recipe.getInputs and recipe:getInputs() or nil

    if inputs == nil then
        return nil
    end

    for inputIndex = 0, inputs:size() - 1 do
        local inputScript = inputs:get(inputIndex)

        if inputScript ~= nil
            and inputScript.isVariableAmount ~= nil
            and inputScript:isVariableAmount() then
            local possibleItems = inputScript:getPossibleInputItems()
            local hasMetalBar = false
            local hasIronBar = false

            if possibleItems ~= nil then
                for itemIndex = 0, possibleItems:size() - 1 do
                    local item = possibleItems:get(itemIndex)
                    local fullType = item
                        and item.getFullName
                        and item:getFullName()
                        or nil

                    hasMetalBar = hasMetalBar or fullType == "Base.MetalBar"
                    hasIronBar = hasIronBar or fullType == "Base.IronBar"
                end
            end

            if hasMetalBar and hasIronBar then
                return recipeData:getDataForInputScript(inputScript)
            end
        end
    end

    return nil
end

local function syncLength(logic, length)
    if logic ~= nil and logic.setTargetVariableInputRatio ~= nil then
        logic:setTargetVariableInputRatio(length / GarageBuild.MinLength)
    end

    local inputData = getBarInputData(logic)
    local recipeData = getRecipeData(logic)

    if inputData ~= nil and recipeData ~= nil then
        while inputData:getInputItemCount() > length
            and inputData:getLastInputItem() ~= nil do
            recipeData:removeInputItem(inputData:getLastInputItem())
        end
    end

    local modData = recipeData
        and recipeData.getModData
        and recipeData:getModData()
        or nil

    if modData ~= nil then
        modData[GarageBuild.LengthModDataKey] = length
    end
end

function GarageLengthState.getSelectedBarCount(logic)
    local inputData = getBarInputData(logic)

    if inputData == nil or inputData.getInputItemCount == nil then
        return 0
    end

    return inputData:getInputItemCount()
end

function GarageLengthState.hasSelectedBars(logic, length)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return true
    end

    return GarageLengthState.getSelectedBarCount(logic)
        >= GarageBuild.normalizeLength(length)
end

function GarageLengthState.getLengthFromLogic(logic)
    if logic == nil then
        return GarageBuild.DefaultLength
    end

    local length = tonumber(lengthByLogic[logic])

    if length == nil then
        local recipeData = getRecipeData(logic)
        local modData = recipeData
            and recipeData.getModData
            and recipeData:getModData()
            or nil

        length = modData
            and tonumber(modData[GarageBuild.LengthModDataKey])
            or GarageBuild.DefaultLength
    end

    length = GarageBuild.normalizeLength(length)
    lengthByLogic[logic] = length
    syncLength(logic, length)

    return length
end

function GarageLengthState.setLengthOnLogic(logic, length)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)
    lengthByLogic[logic] = length
    syncLength(logic, length)

    return length
end

function GarageLengthState.ensureLengthOnLogic(logic)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return nil
    end

    return GarageLengthState.getLengthFromLogic(logic)
end

return GarageLengthState
