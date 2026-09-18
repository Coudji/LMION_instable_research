local ActionContract = {}

local function fail(message)
    error("LMION Moveables ActionContract: " .. message, 3)
end

local function getModeData(definition, mode)
    if type(definition) ~= "table" then
        return nil
    end

    if mode == "pickup" then
        return definition.pickup
    end
    if mode == "place" then
        return definition.replacement
    end

    return nil
end

local function getSkill(definition, mode, modeData)
    local skill = type(modeData) == "table" and modeData.skill or nil

    -- Replacement may intentionally inherit pickup skill. This is a schema
    -- default, not a tool/material heuristic, and can always be overridden by
    -- replacement.skill in the effective definition.
    if mode == "place" and type(skill) ~= "table" then
        skill = definition.pickup and definition.pickup.skill or nil
    end

    if skill == nil then
        return nil, 0
    end
    if type(skill) ~= "table" then
        fail(mode .. ".skill must be a table")
    end

    local name, level = nil, nil
    for skillName, skillLevel in pairs(skill) do
        if name ~= nil then
            fail(mode .. " Moveables action supports one governing skill")
        end
        name = skillName
        level = tonumber(skillLevel)
    end

    if type(name) ~= "string" or name == "" or level == nil then
        fail(mode .. ".skill must contain one valid skill")
    end

    return name, math.max(0, math.floor(level))
end

local function getToolSelector(mode, modeData)
    local tools = type(modeData) == "table" and modeData.tools or nil
    if tools == nil or #tools == 0 then
        return nil
    end
    if type(tools) ~= "table" or #tools ~= 1 or type(tools[1]) ~= "table" then
        fail(mode .. ".tools must contain exactly one selector; use anyOf/anyTagOf for alternatives")
    end
    return tools[1]
end

local function getAction(mode, modeData)
    local action = type(modeData) == "table" and modeData.action or nil
    if action == nil then
        action = {}
    elseif type(action) ~= "table" then
        fail(mode .. ".action must be a table")
    end

    local time = tonumber(action.time)
    if time == nil then
        time = 100
    end
    if time < 0 then
        fail(mode .. ".action.time must be non-negative")
    end

    local sound = action.sound
    if sound ~= nil and (type(sound) ~= "string" or sound == "") then
        fail(mode .. ".action.sound must be a non-empty string when provided")
    end

    local animation = action.animation
    if animation ~= nil and (type(animation) ~= "string" or animation == "") then
        fail(mode .. ".action.animation must be a non-empty string when provided")
    end

    return {
        time = time,
        sound = sound,
        soundIsWav = action.soundIsWav ~= false,
        animation = animation,
    }
end

function ActionContract.getToolDefinitionName(definitionId, mode)
    if type(definitionId) ~= "string" or definitionId == "" then
        return nil
    end
    if mode ~= "pickup" and mode ~= "place" then
        return nil
    end

    return "LMIONV3:" .. definitionId .. ":" .. mode
end

function ActionContract.get(definition, mode)
    local modeData = getModeData(definition, mode)
    if type(modeData) ~= "table" then
        return nil
    end

    local skillName, skillLevel = getSkill(definition, mode, modeData)
    local toolSelector = getToolSelector(mode, modeData)
    local action = getAction(mode, modeData)

    return {
        definitionId = definition.definitionId,
        mode = mode,
        skillName = skillName,
        skillLevel = skillLevel,
        toolSelector = toolSelector,
        toolDefinitionName = toolSelector and ActionContract.getToolDefinitionName(
            definition.definitionId,
            mode
        ) or nil,
        time = action.time,
        sound = action.sound,
        soundIsWav = action.soundIsWav,
        animation = action.animation,
    }
end

return ActionContract
