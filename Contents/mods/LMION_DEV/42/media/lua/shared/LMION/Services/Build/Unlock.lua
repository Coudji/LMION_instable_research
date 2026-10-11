local Unlock = {}

local function fail(message)
    error("LMION Build Unlock: " .. message, 3)
end

local function getConstruction(definition)
    return type(definition) == "table" and definition.construction or nil
end

local function addRequirement(result, skillName, level, label)
    if type(skillName) ~= "string" or skillName == "" then
        fail(label .. ".skill must be a non-empty string")
    end

    level = tonumber(level)
    if level == nil or level < 0 or level ~= math.floor(level) then
        fail(label .. ".level must be a non-negative integer")
    end

    result[#result + 1] = {
        skillName = skillName,
        level = level,
    }
end

local function getRequirements(definition)
    local construction = getConstruction(definition)
    if type(construction) ~= "table" then
        return {}
    end

    local unlock = construction.unlock
    if unlock ~= nil then
        if type(unlock) ~= "table" then
            fail("construction.unlock must be a table")
        end

        local result = {}
        addRequirement(
            result,
            unlock.skill,
            unlock.level,
            "construction.unlock"
        )
        return result
    end

    local skills = construction.skill
    if skills == nil then
        return {}
    end
    if type(skills) ~= "table" then
        fail("construction.skill must be a table")
    end

    local names = {}
    for skillName in pairs(skills) do
        names[#names + 1] = skillName
    end
    table.sort(names)

    local result = {}
    for index = 1, #names do
        local skillName = names[index]
        addRequirement(
            result,
            skillName,
            skills[skillName],
            "construction.skill." .. tostring(skillName)
        )
    end

    return result
end

local function resolvePlayer(player)
    if type(player) == "number" then
        if getSpecificPlayer ~= nil then
            return getSpecificPlayer(player)
        end
        return nil
    end

    if type(player) == "table" or type(player) == "userdata" then
        return player
    end

    return nil
end

local function resolvePerk(skillName)
    if Perks ~= nil and Perks[skillName] ~= nil then
        return Perks[skillName]
    end

    if PerkFactory ~= nil
        and PerkFactory.Perks ~= nil
        and PerkFactory.Perks.FromString ~= nil then
        local perk = PerkFactory.Perks.FromString(skillName)
        if perk ~= nil then
            return perk
        end
    end

    fail("unknown perk " .. tostring(skillName))
end

function Unlock.hasContract(definition)
    return #getRequirements(definition) > 0
end

function Unlock.getProgressionLevel(definition)
    local requirements = getRequirements(definition)
    local highest = 0

    for index = 1, #requirements do
        highest = math.max(highest, requirements[index].level)
    end

    return highest
end

function Unlock.shouldShow(definition, player)
    local requirements = getRequirements(definition)
    if #requirements == 0 then
        return true
    end

    player = resolvePlayer(player)

    if player == nil or player.getPerkLevel == nil then
        return true
    end

    for index = 1, #requirements do
        local requirement = requirements[index]
        local perk = resolvePerk(requirement.skillName)
        if player:getPerkLevel(perk) < requirement.level then
            return false
        end
    end

    return true
end

return Unlock
