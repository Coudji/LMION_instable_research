local PackageContract = {}

local function getShortName(entityId)
    if type(entityId) ~= "string" or entityId == "" then
        return nil
    end
    return string.match(entityId, "^[^.]+%.(.+)$") or entityId
end

local function render(template, context)
    local missing = nil
    local result = string.gsub(template, "{([%w_]+)}", function(key)
        local value = context[key]
        if value == nil then
            missing = key
            return "{" .. key .. "}"
        end
        return tostring(value)
    end)

    if missing ~= nil then
        error("LMION: package itemTemplate is missing context value " .. missing, 3)
    end

    return result
end

function PackageContract.getItemType(definition, context)
    local pickup = definition and definition.pickup or nil
    local packages = type(pickup) == "table" and pickup.packages or nil
    if type(packages) ~= "table" then
        return nil
    end

    if type(packages.item) == "string" and packages.item ~= "" then
        return packages.item
    end

    local template = packages.itemTemplate
    if type(template) ~= "string" or template == "" then
        return nil
    end

    context = context or {}
    if context.entityName == nil then
        context.entityName = getShortName(context.entityId or definition.entity)
    end

    return render(template, context)
end

return PackageContract
