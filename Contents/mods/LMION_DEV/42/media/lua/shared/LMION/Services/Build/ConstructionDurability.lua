local ConstructionDurability = {}

function ConstructionDurability.getEffectiveMaxHealth(definition, craftRecipe, character)
    local durability = definition and definition.durability or nil
    if type(durability) ~= "table" then
        return nil
    end

    local baseHealth = tonumber(durability.health)
    local skillBaseHealth = tonumber(durability.skillBaseHealth) or 0
    if baseHealth == nil then
        return nil
    end

    local skillLevel = 0
    if skillBaseHealth ~= 0
        and craftRecipe ~= nil
        and character ~= nil
        and craftRecipe.getHighestRelevantSkillLevel ~= nil then
        skillLevel = tonumber(craftRecipe:getHighestRelevantSkillLevel(character)) or 0
    end

    return math.max(0, math.floor(baseHealth + skillBaseHealth * skillLevel))
end

return ConstructionDurability
