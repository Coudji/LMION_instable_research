local ItemSelector = {}

local cachedTypesByKey = {}

local function addUnique(result, seen, value)
    if type(value) ~= "string" or value == "" or seen[value] then
        return
    end

    seen[value] = true
    result[#result + 1] = value
end

local function getTagObject(tagName)
    if ItemTag == nil
        or ItemTag.get == nil
        or ResourceLocation == nil
        or ResourceLocation.of == nil then
        return nil
    end

    local okLocation, location = pcall(ResourceLocation.of, tagName)
    if not okLocation or location == nil then
        return nil
    end

    local okTag, tag = pcall(ItemTag.get, location)
    return okTag and tag or nil
end

local function getTagTypes(tagName)
    local result = {}
    local seen = {}

    if type(tagName) ~= "string"
        or tagName == ""
        or ScriptManager == nil
        or ScriptManager.instance == nil then
        return result
    end

    local tag = getTagObject(tagName)
    if tag ~= nil and ScriptManager.instance.getItemsTag ~= nil then
        local okItems, items = pcall(
            ScriptManager.instance.getItemsTag,
            ScriptManager.instance,
            tag
        )
        if okItems and items ~= nil then
            for index = 0, items:size() - 1 do
                local item = items:get(index)
                addUnique(
                    result,
                    seen,
                    item and item.getFullName and item:getFullName() or nil
                )
            end
        end
    end

    -- Keep arbitrary mod tags usable even if getItemsTag is unavailable at a
    -- particular lifecycle point. This fallback still asks PZ's Item script
    -- objects whether they carry the requested registered tag.
    if #result == 0
        and tag ~= nil
        and ScriptManager.instance.getAllItems ~= nil then
        local okItems, items = pcall(
            ScriptManager.instance.getAllItems,
            ScriptManager.instance
        )
        if okItems and items ~= nil then
            for index = 0, items:size() - 1 do
                local item = items:get(index)
                local okHasTag, hasTag = false, false

                if item ~= nil and item.hasTag ~= nil then
                    okHasTag, hasTag = pcall(item.hasTag, item, tag)
                end

                if okHasTag and hasTag then
                    addUnique(
                        result,
                        seen,
                        item.getFullName and item:getFullName() or nil
                    )
                end
            end
        end
    end

    return result
end

local function makeKey(selector)
    if type(selector) ~= "table" then
        return nil
    end

    if selector.item ~= nil then
        return "item:" .. tostring(selector.item)
    end
    if selector.tag ~= nil then
        return "tag:" .. tostring(selector.tag)
    end
    if type(selector.anyOf) == "table" then
        return "items:" .. table.concat(selector.anyOf, "\31")
    end
    if type(selector.anyTagOf) == "table" then
        return "tags:" .. table.concat(selector.anyTagOf, "\31")
    end

    return nil
end

function ItemSelector.getItemTypes(selector)
    local key = makeKey(selector)
    if key == nil then
        return {}
    end

    local cached = cachedTypesByKey[key]
    if cached ~= nil then
        local copy = {}
        for index = 1, #cached do
            copy[index] = cached[index]
        end
        return copy
    end

    local result = {}
    local seen = {}

    if type(selector.item) == "string" then
        addUnique(result, seen, selector.item)
    elseif type(selector.anyOf) == "table" then
        for index = 1, #selector.anyOf do
            addUnique(result, seen, selector.anyOf[index])
        end
    elseif type(selector.tag) == "string" then
        for _, fullType in ipairs(getTagTypes(selector.tag)) do
            addUnique(result, seen, fullType)
        end
    elseif type(selector.anyTagOf) == "table" then
        for index = 1, #selector.anyTagOf do
            for _, fullType in ipairs(getTagTypes(selector.anyTagOf[index])) do
                addUnique(result, seen, fullType)
            end
        end
    end

    cachedTypesByKey[key] = result
    return ItemSelector.getItemTypes(selector)
end

function ItemSelector.clearCache()
    cachedTypesByKey = {}
end

return ItemSelector
