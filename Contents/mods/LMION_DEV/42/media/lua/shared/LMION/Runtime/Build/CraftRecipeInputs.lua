local CraftRecipeInputs = {}

local function fail(message)
    error("LMION CraftRecipeInputs: " .. message, 3)
end

local function requireString(value, message)
    if type(value) ~= "string" or value == "" then
        fail(message)
    end

    return value
end

local function joinValues(values, message)
    if type(values) ~= "table" or #values == 0 then
        fail(message)
    end

    local result = {}
    for index = 1, #values do
        result[index] = requireString(values[index], message)
    end

    return table.concat(result, ";")
end

local function getSelector(input, index, kind)
    if type(input) ~= "table" then
        fail(kind .. " at index " .. tostring(index) .. " must be a table")
    end

    local selectors = 0
    local selector = nil

    if input.tag ~= nil then
        selectors = selectors + 1
        selector = "tags[" .. requireString(
            input.tag,
            kind .. " tag at index " .. tostring(index) .. " must be a non-empty string"
        ) .. "]"
    end

    if input.anyTagOf ~= nil then
        selectors = selectors + 1
        selector = "tags[" .. joinValues(
            input.anyTagOf,
            kind .. " tag alternatives at index " .. tostring(index) .. " must be non-empty strings"
        ) .. "]"
    end

    if input.item ~= nil then
        selectors = selectors + 1
        selector = "[" .. requireString(
            input.item,
            kind .. " item at index " .. tostring(index) .. " must be a non-empty string"
        ) .. "]"
    end

    if input.anyOf ~= nil then
        selectors = selectors + 1
        selector = "[" .. joinValues(
            input.anyOf,
            kind .. " item alternatives at index " .. tostring(index) .. " must be non-empty strings"
        ) .. "]"
    end

    if selectors ~= 1 then
        fail(
            kind
                .. " at index "
                .. tostring(index)
                .. " must define exactly one of tag, anyTagOf, item or anyOf"
        )
    end

    return selector
end

local function appendFlags(target, flags, index, kind)
    if flags == nil then
        return
    end

    if type(flags) ~= "table" then
        fail(kind .. " flags at index " .. tostring(index) .. " must be a table")
    end

    for flagIndex = 1, #flags do
        local flag = requireString(
            flags[flagIndex],
            kind .. " flag at index " .. tostring(index) .. " must be a non-empty string"
        )

        local exists = false
        for existingIndex = 1, #target do
            if target[existingIndex] == flag then
                exists = true
                break
            end
        end

        if not exists then
            target[#target + 1] = flag
        end
    end
end

local function addInputLine(lines, quantity, selector, mode, flags)
    local line = "        item " .. tostring(quantity) .. " " .. selector

    if mode ~= nil then
        line = line .. " mode:" .. mode
    end

    if #flags > 0 then
        line = line .. " flags[" .. table.concat(flags, ";") .. "]"
    end

    lines[#lines + 1] = line .. ","
end

function CraftRecipeInputs.addTools(lines, tools)
    if tools == nil then
        return
    end

    if type(tools) ~= "table" then
        fail("construction.tools must be a table")
    end

    for index = 1, #tools do
        local tool = tools[index]
        local selector = getSelector(tool, index, "construction tool")
        local amount = tonumber(tool.amount) or 1

        if amount < 1 or amount ~= math.floor(amount) then
            fail("construction tool amount at index " .. tostring(index) .. " must be a positive integer")
        end

        local mode = tool.mode
        if mode == nil then
            mode = "keep"
        else
            mode = requireString(
                mode,
                "construction tool mode at index " .. tostring(index) .. " must be a non-empty string"
            )
        end

        local flags = {}
        appendFlags(flags, tool.flags, index, "construction tool")
        addInputLine(lines, amount, selector, mode, flags)
    end
end

function CraftRecipeInputs.addMaterials(lines, materials)
    if materials == nil then
        return
    end

    if type(materials) ~= "table" then
        fail("construction.materials must be a table")
    end

    for index = 1, #materials do
        local material = materials[index]
        local selector = getSelector(material, index, "construction material")
        local amount = tonumber(material.amount)
        local uses = tonumber(material.uses)

        if (amount == nil) == (uses == nil) then
            fail(
                "construction material must define exactly one of amount or uses at index "
                    .. tostring(index)
            )
        end

        local quantity = amount or uses
        if quantity < 1 or quantity ~= math.floor(quantity) then
            fail(
                "construction material quantity at index "
                    .. tostring(index)
                    .. " must be a positive integer"
            )
        end

        local mode = material.mode
        if mode ~= nil then
            mode = requireString(
                mode,
                "construction material mode at index " .. tostring(index) .. " must be a non-empty string"
            )
        end

        local flags = {}
        appendFlags(flags, material.flags, index, "construction material")

        if uses ~= nil then
            local hasDontRecord = false
            for flagIndex = 1, #flags do
                if flags[flagIndex] == "DontRecordInput" then
                    hasDontRecord = true
                    break
                end
            end
            if not hasDontRecord then
                flags[#flags + 1] = "DontRecordInput"
            end
        end

        addInputLine(lines, quantity, selector, mode, flags)
    end
end

return CraftRecipeInputs
