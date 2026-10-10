local Unlock = {}

local function fail(message)
    error("LMION Build Unlock: " .. message, 3)
end

local function getContract(definition)
    local construction = type(definition) == "table" and definition.construction or nil
    local unlock = type(construction) == "table" and construction.unlock or nil

    if unlock == nil then
        return nil
    end
    if type(unlock) ~= "table" then
        fail("construction.unlock must be a table")
    end

    local skillName = unlock.skill
    local level = tonumber(unlock.level)

    if type(skillName) ~= "string" or skillName == "" then
        fail("construction.unlock.skill must be a non-empty string")
    end
    if level == nil or level < 0 or level ~= math.floor(level) then
        fail("construction.unlock.level must be a non-negative integer")
    end

    return {
        skillName = skillName,
        level = level,
    }
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
    local construction = type(definition) == "table" and definition.construction or nil
    return type(construction) == "table" and construction.unlock ~= nil
end

function Unlock.shouldShow(definition, player)
    local contract = getContract(definition)
    if contract == nil then
        return true
    end

    -- Build-menu callbacks normally receive a player. If PZ invokes the
    -- callback from a non-player inspection path, don't hide content merely
    -- because that context cannot evaluate progression.
    if player == nil or player.getPerkLevel == nil then
        return true
    end

    local perk = resolvePerk(contract.skillName)
    return player:getPerkLevel(perk) >= contract.level
end

return Unlock
