local MoveableProfileFields = {}

local function hasSkill(skill, skillName)
    return type(skill) == "table" and skill[skillName] ~= nil
end

function MoveableProfileFields.getSingleSkillLevel(skill)
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

function MoveableProfileFields.getSingleToolName(tools, governingSkill)
    if type(tools) ~= "table" or #tools ~= 1 then
        return nil
    end

    local tool = tools[1]
    if type(tool) ~= "table" then
        return nil
    end

    local metal = hasSkill(governingSkill, "MetalWelding")

    if tool.tag == "base:screwdriver" then
        return metal and "LMIONMetalScrewdriver" or "Screwdriver"
    end
    if tool.tag == "base:crowbar" then
        return metal and "LMIONMetalCrowbar" or "Crowbar"
    end
    if tool.tag == "base:hammer" then
        return metal and "LMIONMetalHammer" or "Hammer"
    end

    return nil
end

function MoveableProfileFields.getItemType(entityId)
    if type(entityId) ~= "string" then
        return nil
    end

    local shortName = string.match(entityId, "^[^.]+%.(.+)$") or entityId
    if shortName == "" then
        return nil
    end

    return "Base.LMION_" .. shortName
end

function MoveableProfileFields.hasScriptItem(itemType)
    return itemType ~= nil
        and ScriptManager ~= nil
        and ScriptManager.instance ~= nil
        and ScriptManager.instance:FindItem(itemType) ~= nil
end

function MoveableProfileFields.getPackageWeight(pickup)
    local packages = type(pickup) == "table" and pickup.packages or nil
    if type(packages) ~= "table" then
        return nil
    end

    return tonumber(packages.weight)
end

return MoveableProfileFields
