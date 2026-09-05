local SingleTileProfileFields = {}

function SingleTileProfileFields.getSingleSkillLevel(skill)
    if type(skill) ~= "table" then
        return 0
    end

    local count = 0
    local level = nil

    for _, value in pairs(skill) do
        count = count + 1
        if count > 1 then
            return nil
        end
        level = value
    end

    if count == 0 then
        return 0
    end

    return tonumber(level) or 0
end

function SingleTileProfileFields.getSingleToolName(tools)
    if type(tools) ~= "table" or #tools ~= 1 then
        return nil
    end

    local tool = tools[1]
    if type(tool) ~= "table" then
        return nil
    end

    if tool.tag == "base:screwdriver" then
        return "Screwdriver"
    end

    return nil
end

function SingleTileProfileFields.getItemType(entityId)
    if type(entityId) ~= "string" then
        return nil
    end

    local shortName = string.match(entityId, "^[^.]+%.(.+)$") or entityId
    if shortName == "" then
        return nil
    end

    return "Base.LMION_" .. shortName
end

function SingleTileProfileFields.hasScriptItem(itemType)
    return itemType ~= nil
        and ScriptManager ~= nil
        and ScriptManager.instance ~= nil
        and ScriptManager.instance:FindItem(itemType) ~= nil
end

function SingleTileProfileFields.getPackageWeight(pickup)
    local packages = type(pickup) == "table" and pickup.packages or nil
    if type(packages) ~= "table" then
        return nil
    end

    return tonumber(packages.weight)
end

return SingleTileProfileFields
