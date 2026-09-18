local ActionContract = require "LMION/Services/Moveables/ActionContract"
local PackageContract = require "LMION/Services/Moveables/PackageContract"

local MoveableProfileFields = {}

function MoveableProfileFields.getAction(definition, mode)
    return ActionContract.get(definition, mode)
end

function MoveableProfileFields.getToolName(definition, mode)
    local action = ActionContract.get(definition, mode)
    return action and action.toolDefinitionName or nil
end

function MoveableProfileFields.getSkillLevel(definition, mode)
    local action = ActionContract.get(definition, mode)
    return action and action.skillLevel or 0
end

function MoveableProfileFields.getPackageItemType(definition, context)
    return PackageContract.getItemType(definition, context)
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

function MoveableProfileFields.getBreakChance(pickup)
    if type(pickup) ~= "table" then
        return 0
    end

    local chance = tonumber(pickup.breakChance) or 0
    return math.max(0, math.min(100, chance))
end

return MoveableProfileFields
