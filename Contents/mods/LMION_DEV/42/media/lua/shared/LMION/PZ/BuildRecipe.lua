local BuildRecipe = {}

local function getEntityShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

function BuildRecipe.getByName(recipeName)
    if type(recipeName) ~= "string"
        or recipeName == ""
        or ScriptManager == nil
        or ScriptManager.instance == nil then
        return nil
    end

    return ScriptManager.instance:getBuildableRecipe(recipeName)
end

function BuildRecipe.getByEntityId(entityId)
    local recipeName = getEntityShortName(entityId)
    if recipeName == nil then
        return nil
    end

    return BuildRecipe.getByName(recipeName)
end

function BuildRecipe.getNameForEntityId(entityId)
    return getEntityShortName(entityId)
end

function BuildRecipe.isEmptyShell(recipe)
    if recipe == nil or recipe.getInputCount == nil then
        return false
    end

    return recipe:getInputCount() == 0
end

return BuildRecipe
