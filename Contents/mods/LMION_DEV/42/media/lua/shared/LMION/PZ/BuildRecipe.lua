local BuildRecipe = {}

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

    local current = recipe
    local visited = {}

    while current ~= nil and not visited[current] do
        visited[current] = true

        if current.getFullName ~= nil then
            local ok, fullName = pcall(current.getFullName, current)
            if ok and type(fullName) == "string" and fullName ~= "" then
                return fullName
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

return BuildRecipe
