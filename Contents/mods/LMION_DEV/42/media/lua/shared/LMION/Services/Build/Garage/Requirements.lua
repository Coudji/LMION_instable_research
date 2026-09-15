local GarageBuild = require "LMION/Services/Build/Garage/Build"

local GarageRequirements = {}

local RESOURCE_TYPES = {
    "Base.BlowTorch",
    "Base.SmallSheetMetal",
    "Base.GlassPanel",
    "Base.MetalBar",
    "Base.IronBar",
    "Base.Hinge",
    "Base.WeldingRods",
}

local BASE_REQUIREMENTS = {
    solid = {
        BlowTorch = 1,
        SmallSheetMetal = 6,
        Bars = 2,
        Hinge = 4,
        WeldingRods = 2,
    },
    glazed = {
        BlowTorch = 1,
        SmallSheetMetal = 4,
        GlassPanel = 2,
        Bars = 2,
        Hinge = 4,
        WeldingRods = 2,
    },
}

local KEY_TO_TYPE = {
    BlowTorch = "Base.BlowTorch",
    SmallSheetMetal = "Base.SmallSheetMetal",
    GlassPanel = "Base.GlassPanel",
    Hinge = "Base.Hinge",
    WeldingRods = "Base.WeldingRods",
}

local TYPE_TO_KEY = {
    ["Base.BlowTorch"] = "BlowTorch",
    ["Base.SmallSheetMetal"] = "SmallSheetMetal",
    ["Base.GlassPanel"] = "GlassPanel",
    ["Base.MetalBar"] = "Bars",
    ["Base.IronBar"] = "Bars",
    ["Base.Hinge"] = "Hinge",
    ["Base.WeldingRods"] = "WeldingRods",
}

local lastConsumedByCharacter = setmetatable({}, { __mode = "k" })

local function isGlazed(profile)
    local materials = profile
        and profile.definition
        and profile.definition.engineMaterials
        or {}

    for _, material in ipairs(materials) do
        if material == "Glass" then
            return true
        end
    end

    return false
end

function GarageRequirements.getRequirements(profile, width)
    if profile == nil then
        return nil
    end

    width = GarageBuild.normalizeWidth(width)
    local steps = math.ceil(width / 3)

    local requirements = {
        BlowTorch = {
            amount = math.min(steps, 10),
            uses = true,
        },
        Bars = {
            amount = width,
        },
        Hinge = {
            amount = width * 2,
        },
        WeldingRods = {
            amount = math.min(steps * 2, 20),
            uses = true,
        },
    }

    if isGlazed(profile) then
        requirements.SmallSheetMetal = {
            amount = width * 2,
        }
        requirements.GlassPanel = {
            amount = width,
        }
    else
        requirements.SmallSheetMetal = {
            amount = width * 3,
        }
    end

    return requirements
end

local function addStockItem(entry, item, seen)
    if item == nil or seen[item] then
        return
    end

    seen[item] = true
    entry.items[#entry.items + 1] = item
    entry.count = entry.count + 1

    if instanceof(item, "DrainableComboItem")
        and item:getCurrentUses() > 0 then
        entry.uses = entry.uses + item:getCurrentUses()
    end
end

local function addContainerStock(entry, container, fullType, seen)
    if container == nil or ISBuildIsoEntity == nil then
        return
    end

    local items = container:getAllTypeEvalRecurse(
        fullType,
        ISBuildIsoEntity.predicateMaterial
    )

    if items == nil then
        return
    end

    for index = 0, items:size() - 1 do
        addStockItem(entry, items:get(index), seen)
    end
end

function GarageRequirements.getStock(character, containers)
    local stock = {}
    local groundItems = character
        and ISBuildIsoEntity
        and ISBuildIsoEntity.GetAllGroundItemsForPlayer(character)
        or nil

    for _, fullType in ipairs(RESOURCE_TYPES) do
        local entry = {
            count = 0,
            uses = 0,
            items = {},
        }
        local seen = {}

        addContainerStock(
            entry,
            character and character:getInventory() or nil,
            fullType,
            seen
        )

        if containers ~= nil then
            for index = 0, containers:size() - 1 do
                addContainerStock(
                    entry,
                    containers:get(index),
                    fullType,
                    seen
                )
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

local function getAvailableAmount(stock, key, uses)
    if key == "Bars" then
        return (stock["Base.MetalBar"].count or 0)
            + (stock["Base.IronBar"].count or 0)
    end

    local entry = stock[KEY_TO_TYPE[key]]
    if entry == nil then
        return 0
    end

    return uses and entry.uses or entry.count
end

function GarageRequirements.hasRequirements(character, profile, width, containers)
    local requirements = GarageRequirements.getRequirements(profile, width)
    if requirements == nil then
        return true
    end

    local stock = GarageRequirements.getStock(character, containers)

    for key, requirement in pairs(requirements) do
        if getAvailableAmount(stock, key, requirement.uses) < requirement.amount then
            return false
        end
    end

    return true
end

function GarageRequirements.getAvailable(character, key, uses, containers)
    local stock = GarageRequirements.getStock(character, containers)
    return getAvailableAmount(stock, key, uses)
end

function GarageRequirements.getRequirement(profile, width, fullType)
    local key = TYPE_TO_KEY[fullType]
    local requirements = GarageRequirements.getRequirements(profile, width)

    if key == nil or requirements == nil then
        return nil, key
    end

    return requirements[key], key
end

local function consumeItems(character, uses, amount, items, recorded)
    local remaining = amount

    for _, item in ipairs(items or {}) do
        if remaining <= 0 then
            break
        end

        if uses then
            if item ~= nil and item:getCurrentUses() > 0 then
                remaining = remaining - buildUtil.useDrainable(item, remaining)
            end
        else
            local fullType = item and item:getFullType() or nil
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

    return remaining
end

function GarageRequirements.consumeExtras(
    character,
    profile,
    width,
    containers,
    vanillaBarCount
)
    local requirements = GarageRequirements.getRequirements(profile, width)
    if requirements == nil then
        return true
    end

    local baseRequirements = isGlazed(profile)
        and BASE_REQUIREMENTS.glazed
        or BASE_REQUIREMENTS.solid
    local stock = GarageRequirements.getStock(character, containers)
    local jobs = {}

    for key, requirement in pairs(requirements) do
        local amount = nil

        if key == "Bars" then
            amount = math.max(
                0,
                width - math.max(0, tonumber(vanillaBarCount) or 0)
            )
        else
            amount = math.max(
                0,
                requirement.amount - (baseRequirements[key] or 0)
            )
        end

        if amount > 0 then
            if getAvailableAmount(stock, key, requirement.uses) < amount then
                return false
            end

            jobs[#jobs + 1] = {
                key = key,
                amount = amount,
                uses = requirement.uses,
            }
        end
    end

    local recorded = {}

    for _, job in ipairs(jobs) do
        local items = nil

        if job.key == "Bars" then
            items = {}

            for _, fullType in ipairs({ "Base.MetalBar", "Base.IronBar" }) do
                for _, item in ipairs(stock[fullType].items) do
                    items[#items + 1] = item
                end
            end
        else
            items = stock[KEY_TO_TYPE[job.key]].items
        end

        if consumeItems(
            character,
            job.uses,
            job.amount,
            items,
            recorded
        ) > 0 then
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
