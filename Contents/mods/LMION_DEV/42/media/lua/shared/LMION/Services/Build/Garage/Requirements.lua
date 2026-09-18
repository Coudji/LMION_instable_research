local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageMaterials = require "LMION/Services/Build/Garage/Materials"

local GarageRequirements = {}
local lastConsumedByCharacter = setmetatable({}, { __mode = "k" })

local function addStockItem(entry, item, seen)
    if item == nil or seen[item] then
        return
    end
    seen[item] = true
    entry.items[#entry.items + 1] = item
    entry.count = entry.count + 1
    if instanceof(item, "DrainableComboItem") and item:getCurrentUses() > 0 then
        entry.uses = entry.uses + item:getCurrentUses()
    end
end

local function addContainerStock(entry, container, fullType, seen)
    if container == nil or ISBuildIsoEntity == nil then
        return
    end
    local items = container:getAllTypeEvalRecurse(fullType, ISBuildIsoEntity.predicateMaterial)
    if items == nil then
        return
    end
    for index = 0, items:size() - 1 do
        addStockItem(entry, items:get(index), seen)
    end
end

local function collectTypes(requirements)
    local types = {}
    local seen = {}
    for index = 1, #requirements do
        for typeIndex = 1, #requirements[index].itemTypes do
            local fullType = requirements[index].itemTypes[typeIndex]
            if not seen[fullType] then
                seen[fullType] = true
                types[#types + 1] = fullType
            end
        end
    end
    return types
end

function GarageRequirements.getRequirements(profile, width)
    local definition = profile and profile.definition or nil
    return definition and GarageMaterials.getRequirements(definition, GarageBuild.normalizeWidth(width)) or nil
end

function GarageRequirements.getStock(character, profile, width, containers)
    local requirements = GarageRequirements.getRequirements(profile, width) or {}
    local stock = {}
    local groundItems = character and ISBuildIsoEntity and ISBuildIsoEntity.GetAllGroundItemsForPlayer(character) or nil

    for _, fullType in ipairs(collectTypes(requirements)) do
        local entry = { count = 0, uses = 0, items = {} }
        local seen = {}
        addContainerStock(entry, character and character:getInventory() or nil, fullType, seen)

        if containers ~= nil then
            for index = 0, containers:size() - 1 do
                addContainerStock(entry, containers:get(index), fullType, seen)
            end
        end

        local groundEntry = groundItems and groundItems[fullType] or nil
        if groundEntry ~= nil and groundEntry.items ~= nil then
            for _, item in ipairs(groundEntry.items) do
                addStockItem(entry, item, seen)
            end
        end
        stock[fullType] = entry
    end

    return stock
end

local function getAvailableAmount(stock, requirement)
    local total = 0
    for index = 1, #requirement.itemTypes do
        local entry = stock[requirement.itemTypes[index]]
        if entry ~= nil then
            total = total + (requirement.uses and entry.uses or entry.count)
        end
    end
    return total
end

function GarageRequirements.hasRequirements(character, profile, width, containers)
    local requirements = GarageRequirements.getRequirements(profile, width)
    if requirements == nil then
        return true
    end
    local stock = GarageRequirements.getStock(character, profile, width, containers)
    for index = 1, #requirements do
        local requirement = requirements[index]
        if getAvailableAmount(stock, requirement) < requirement.amount then
            return false
        end
    end
    return true
end

function GarageRequirements.getAvailable(character, profile, width, requirement, containers)
    local stock = GarageRequirements.getStock(character, profile, width, containers)
    return getAvailableAmount(stock, requirement)
end

function GarageRequirements.getRequirement(profile, width, fullType)
    local definition = profile and profile.definition or nil
    if definition == nil then
        return nil
    end
    return GarageMaterials.findRequirementForType(
        definition,
        GarageBuild.normalizeWidth(width),
        fullType
    )
end

local function consumeItems(character, requirement, amount, stock, recorded)
    local remaining = amount
    for typeIndex = 1, #requirement.itemTypes do
        local fullType = requirement.itemTypes[typeIndex]
        local entry = stock[fullType]
        for _, item in ipairs(entry and entry.items or {}) do
            if remaining <= 0 then
                break
            end

            if requirement.uses then
                if item ~= nil and item:getCurrentUses() > 0 then
                    remaining = remaining - buildUtil.useDrainable(item, remaining)
                end
            else
                character:removeFromHands(item)
                local worldItem = item and item:getWorldItem() or nil
                local square = worldItem and worldItem:getSquare() or nil
                if square ~= nil then
                    square:transmitRemoveItemFromSquare(worldItem)
                    square:removeWorldObject(worldItem)
                    if item:getWorldItem() == worldItem then
                        item:setWorldItem(nil)
                    end
                    remaining = remaining - 1
                    recorded[fullType] = (recorded[fullType] or 0) + 1
                else
                    local container = item and item:getContainer() or nil
                    if container ~= nil then
                        container:Remove(item)
                        remaining = remaining - 1
                        recorded[fullType] = (recorded[fullType] or 0) + 1
                    end
                end
            end
        end
        if remaining <= 0 then
            break
        end
    end
    return remaining
end

function GarageRequirements.consumeExtras(character, profile, width, containers, vanillaVariableCount)
    local requirements = GarageRequirements.getRequirements(profile, width)
    local baseRequirements = GarageRequirements.getRequirements(profile, GarageBuild.MinWidth)
    if requirements == nil or baseRequirements == nil then
        return true
    end

    local baseByIndex = {}
    for index = 1, #baseRequirements do
        baseByIndex[baseRequirements[index].index] = baseRequirements[index]
    end

    local stock = GarageRequirements.getStock(character, profile, width, containers)
    local jobs = {}
    for index = 1, #requirements do
        local requirement = requirements[index]
        local base = baseByIndex[requirement.index]
        local consumedByVanilla = base and base.amount or 0

        if requirement.widthInput then
            consumedByVanilla = math.max(0, tonumber(vanillaVariableCount) or 0)
        end

        local extra = math.max(0, requirement.amount - consumedByVanilla)
        if extra > 0 then
            if getAvailableAmount(stock, requirement) < extra then
                return false
            end
            jobs[#jobs + 1] = { requirement = requirement, amount = extra }
        end
    end

    local recorded = {}
    for index = 1, #jobs do
        local job = jobs[index]
        if consumeItems(character, job.requirement, job.amount, stock, recorded) > 0 then
            return false
        end
    end

    lastConsumedByCharacter[character] = recorded
    return true
end

function GarageRequirements.recordExtras(buildObject)
    local character = buildObject and buildObject.character or nil
    local recorded = character and lastConsumedByCharacter[character] or nil
    if recorded == nil or buildObject.modData == nil then
        return
    end

    lastConsumedByCharacter[character] = nil
    for fullType, count in pairs(recorded) do
        local key = "need:" .. fullType
        buildObject.modData[key] = (tonumber(buildObject.modData[key]) or 0) + count
    end
end

return GarageRequirements
