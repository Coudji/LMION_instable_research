local ItemSelector = require "LMION/PZ/ItemSelector"

local GarageMaterials = {}

local function fail(message)
    error("LMION GarageMaterials: " .. message, 3)
end

local function requireNumber(value, label)
    local number = tonumber(value)
    if number == nil then
        fail(label .. " must be numeric")
    end
    return number
end

local function evaluateQuantity(value, width, label)
    if type(value) == "number" then
        return value
    end
    if type(value) ~= "table" then
        fail(label .. " must be a number or width-scaling table")
    end

    local amount = nil

    if value.perWidth ~= nil then
        amount = width * requireNumber(value.perWidth, label .. ".perWidth")
    elseif value.perStep ~= nil then
        local step = value.step ~= nil
            and requireNumber(value.step, label .. ".step")
            or 1

        if step <= 0 then
            fail(label .. ".step must be positive")
        end

        amount = math.ceil(width / step)
            * requireNumber(value.perStep, label .. ".perStep")
    elseif value.fixed ~= nil then
        amount = requireNumber(value.fixed, label .. ".fixed")
    else
        fail(label .. " must define perWidth, perStep or fixed")
    end

    if value.min ~= nil then
        amount = math.max(
            amount,
            requireNumber(value.min, label .. ".min")
        )
    end
    if value.max ~= nil then
        amount = math.min(
            amount,
            requireNumber(value.max, label .. ".max")
        )
    end

    amount = math.floor(amount)
    if amount < 0 then
        fail(label .. " resolved to a negative quantity")
    end

    return amount
end

local function copyArray(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}
    for index = 1, #source do
        result[index] = source[index]
    end
    return result
end

local function copySelector(source, target)
    target.item = source.item
    target.tag = source.tag
    target.anyOf = copyArray(source.anyOf)
    target.anyTagOf = copyArray(source.anyTagOf)
end

function GarageMaterials.getRequirements(definition, width)
    local construction = definition and definition.construction or nil
    local materials = construction and construction.materials or nil
    if type(materials) ~= "table" then
        return nil
    end

    local requirements = {}
    for index = 1, #materials do
        local material = materials[index]
        if type(material) ~= "table" then
            fail(
                "construction material at index "
                    .. tostring(index)
                    .. " must be a table"
            )
        end

        local hasAmount = material.amount ~= nil
        local hasUses = material.uses ~= nil
        if hasAmount == hasUses then
            fail(
                "construction material at index "
                    .. tostring(index)
                    .. " must define exactly one of amount or uses"
            )
        end

        local kind = hasUses and "uses" or "amount"
        local quantity = evaluateQuantity(
            hasUses and material.uses or material.amount,
            width,
            "construction.materials[" .. tostring(index) .. "]." .. kind
        )

        local requirement = {
            index = index,
            descriptor = material,
            kind = kind,
            amount = quantity,
            uses = hasUses,
            widthInput = material.widthInput == true,
            itemTypes = ItemSelector.getItemTypes(material),
        }

        requirements[#requirements + 1] = requirement
    end

    return requirements
end

function GarageMaterials.getRecipeMaterials(definition, width)
    local requirements = GarageMaterials.getRequirements(definition, width)
    if requirements == nil then
        return nil
    end

    local result = {}
    for index = 1, #requirements do
        local requirement = requirements[index]
        local source = requirement.descriptor
        local material = {
            mode = source.mode,
            flags = copyArray(source.flags),
        }

        copySelector(source, material)

        if requirement.uses then
            material.uses = requirement.amount
        else
            material.amount = requirement.amount
        end

        if requirement.widthInput then
            material.variable = {
                min = requirement.amount,
                max = 2147483647,
            }
        end

        result[index] = material
    end

    return result
end

function GarageMaterials.getWidthInputRequirement(definition, width)
    local requirements = GarageMaterials.getRequirements(definition, width)
    if requirements == nil then
        return nil
    end

    local found = nil
    for index = 1, #requirements do
        if requirements[index].widthInput then
            if found ~= nil then
                fail("garage construction may define only one widthInput material")
            end
            found = requirements[index]
        end
    end

    return found
end

function GarageMaterials.findRequirementForType(definition, width, fullType)
    local requirements = GarageMaterials.getRequirements(definition, width)
    if requirements == nil then
        return nil
    end

    for index = 1, #requirements do
        local requirement = requirements[index]
        for typeIndex = 1, #requirement.itemTypes do
            if requirement.itemTypes[typeIndex] == fullType then
                return requirement
            end
        end
    end

    return nil
end

return GarageMaterials
