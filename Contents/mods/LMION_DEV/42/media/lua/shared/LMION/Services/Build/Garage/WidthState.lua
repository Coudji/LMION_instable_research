local GarageBuild = require "LMION/Services/Build/Garage/Build"

local GarageWidthState = {}
local widthByLogic = setmetatable({}, { __mode = "k" })

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

local function syncWidth(logic, width)
    if logic ~= nil and logic.setTargetVariableInputRatio ~= nil then
        logic:setTargetVariableInputRatio(width / GarageBuild.MinWidth)
    end

    local inputData = getBarInputData(logic)
    local recipeData = getRecipeData(logic)

    if inputData ~= nil and recipeData ~= nil then
        while inputData:getInputItemCount() > width
            and inputData:getLastInputItem() ~= nil do
            recipeData:removeInputItem(inputData:getLastInputItem())
        end
    end

    local modData = recipeData
        and recipeData.getModData
        and recipeData:getModData()
        or nil

    if modData ~= nil then
        modData[GarageBuild.WidthModDataKey] = width
    end
end

function GarageWidthState.getSelectedBarCount(logic)
    local inputData = getBarInputData(logic)

    if inputData == nil or inputData.getInputItemCount == nil then
        return 0
    end

    return inputData:getInputItemCount()
end

function GarageWidthState.hasSelectedBars(logic, width)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return true
    end

    return GarageWidthState.getSelectedBarCount(logic)
        >= GarageBuild.normalizeWidth(width)
end

function GarageWidthState.getWidthFromLogic(logic)
    if logic == nil then
        return GarageBuild.DefaultWidth
    end

    local width = tonumber(widthByLogic[logic])

    if width == nil then
        local recipeData = getRecipeData(logic)
        local modData = recipeData
            and recipeData.getModData
            and recipeData:getModData()
            or nil

        width = modData
            and tonumber(modData[GarageBuild.WidthModDataKey])
            or GarageBuild.DefaultWidth
    end

    width = GarageBuild.normalizeWidth(width)
    widthByLogic[logic] = width
    syncWidth(logic, width)

    return width
end

function GarageWidthState.setWidthOnLogic(logic, width)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return nil
    end

    width = GarageBuild.normalizeWidth(width)
    widthByLogic[logic] = width
    syncWidth(logic, width)

    return width
end

function GarageWidthState.ensureWidthOnLogic(logic)
    if GarageBuild.getProfileFromLogic(logic) == nil then
        return nil
    end

    return GarageWidthState.getWidthFromLogic(logic)
end

return GarageWidthState
