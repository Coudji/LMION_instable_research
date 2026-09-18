local BuildRecipe = {}

local ENTITY_RECIPE_SCRIPT = [[
CraftRecipe
{
    tags = EntityRecipe,
}
]]

local function getEntityShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end

    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function getRecipeComponent(entityId)
    if type(entityId) ~= "string"
        or entityId == ""
        or ScriptManager == nil
        or ScriptManager.instance == nil
        or ScriptManager.instance.getGameEntityScript == nil
        or ComponentType == nil
        or ComponentType.CraftRecipe == nil then
        return nil
    end

    local entity = ScriptManager.instance:getGameEntityScript(entityId)
    if entity == nil or entity.getComponentScriptFor == nil then
        return nil
    end

    return entity:getComponentScriptFor(ComponentType.CraftRecipe)
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
    local component = getRecipeComponent(entityId)
    if component ~= nil and component.getCraftRecipe ~= nil then
        return component:getCraftRecipe()
    end

    -- Compatibility fallback for lifecycle points where GameEntity component
    -- lookup is not yet available. Runtime variant selection uses entity ids.
    local recipeName = getEntityShortName(entityId)
    return recipeName and BuildRecipe.getByName(recipeName) or nil
end

function BuildRecipe.getEntityId(recipe)
    if recipe == nil then
        return nil
    end

    if recipe.getScriptObjectFullType ~= nil then
        local ok, fullType = pcall(recipe.getScriptObjectFullType, recipe)
        if ok and type(fullType) == "string" and fullType ~= "" then
            return fullType
        end
    end

    local current = recipe.getParent ~= nil and recipe:getParent() or nil
    local visited = {}

    while current ~= nil and not visited[current] do
        visited[current] = true

        if current.getScriptObjectFullType ~= nil then
            local ok, fullType = pcall(current.getScriptObjectFullType, current)
            if ok and type(fullType) == "string" and fullType ~= "" then
                return fullType
            end
        end

        current = current.getParent ~= nil and current:getParent() or nil
    end

    return nil
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

function BuildRecipe.reload(recipe, script)
    if recipe == nil then
        error("LMION BuildRecipe: recipe is required", 2)
    end
    if type(script) ~= "string" or script == "" then
        error("LMION BuildRecipe: recipe script is required", 2)
    end
    if recipe.PreReload == nil
        or recipe.Load == nil
        or recipe.OnScriptsLoaded == nil
        or recipe.getName == nil then
        error("LMION BuildRecipe: recipe does not expose the reload lifecycle", 2)
    end

    -- CraftRecipe:Load appends IO data, so projection refreshes need the same
    -- reset phase as PZ's script hot reload. Embedded GameEntity recipes also
    -- receive the EntityRecipe tag from CraftRecipeComponentScript.load(); a
    -- direct recipe reload bypasses that component step, so replay the marker
    -- before applying the definition-owned recipe body.
    local recipeName = recipe:getName()
    recipe:PreReload()
    recipe:Load(recipeName, ENTITY_RECIPE_SCRIPT)
    recipe:Load(recipeName, script)
    recipe:OnScriptsLoaded(nil)

    return recipe
end

return BuildRecipe
