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
    if type(entityId) ~= "string"
        or entityId == ""
        or ScriptManager == nil
        or ScriptManager.instance == nil then
        return nil
    end

    if ScriptManager.instance.getGameEntityScript ~= nil
        and ComponentType ~= nil
        and ComponentType.CraftRecipe ~= nil then
        local entity = ScriptManager.instance:getGameEntityScript(entityId)
        if entity ~= nil and entity.getComponentScriptFor ~= nil then
            local component = entity:getComponentScriptFor(ComponentType.CraftRecipe)
            if component ~= nil and component.getCraftRecipe ~= nil then
                return component:getCraftRecipe()
            end
            return nil
        end
    end

    local recipeName = getEntityShortName(entityId)
    return recipeName and BuildRecipe.getByName(recipeName) or nil
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
