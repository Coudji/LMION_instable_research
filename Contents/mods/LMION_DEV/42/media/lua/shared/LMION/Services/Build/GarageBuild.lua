local GarageLengthPolicy = require "LMION/Domain/GarageLengthPolicy"
local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"

local GarageBuild = {
    DefaultLength = 3,
    MinLength = 2,
    LengthModDataKey = "LMIONGarageBuildLength",
}

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

local lastConsumedByCharacter = setmetatable({}, { __mode = "k" })

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

function GarageBuild.normalizeLength(length)
    length = math.max(
        GarageBuild.MinLength,
        math.floor(tonumber(length) or GarageBuild.DefaultLength)
    )

    local maximum = GarageLengthPolicy.getMaximumLength()
    if maximum ~= nil then
        return math.min(length, maximum)
    end

    return length
end

local function getGameScript(objectInfo)
    local spriteScript = objectInfo
        and objectInfo.getScript
        and objectInfo:getScript()
        or nil

    return spriteScript and spriteScript:getParent() or nil
end

function GarageBuild.getProfileFromObjectInfo(objectInfo)
    local script = getGameScript(objectInfo)
    if script == nil then
        return nil
    end

    local fullName = script.getFullName
        and script:getFullName()
        or ("Base." .. tostring(script:getName()))

    for _, definitionId in ipairs(GarageProfiles.getDefinitionIds()) do
        local profile = GarageProfiles.getByDefinitionId(definitionId)
        local entityName = string.match(profile.entityId, "[^.]+$")

        if profile.entityId == fullName or entityName == script:getName() then
            return profile
        end
    end

    return nil
end

function GarageBuild.getProfileFromLogic(logic)
    local objectInfo = logic
        and logic.getSelectedBuildObject
        and logic:getSelectedBuildObject()
        or nil

    return GarageBuild.getProfileFromObjectInfo(objectInfo)
end

local function isGlazed(profile)
    local materials = profile
        and profile.definition
        and profile.definition.engineMaterials
        or {}

    for _, material in ipairs(materials or {}) do
        if material == "Glass" then
            return true
        end
    end

    return false
end

function GarageBuild.getRequirements(profile, length)
    if profile == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)
    local steps = math.ceil(length / 3)

    local requirements = {
        BlowTorch = {
            amount = math.min(steps, 10),
            uses = true,
        },
        Bars = {
            amount = length,
        },
        Hinge = {
            amount = length * 2,
        },
        WeldingRods = {
            amount = math.min(steps * 2, 20),
            uses = true,
        },
    }

    if isGlazed(profile) then
        requirements.SmallSheetMetal = {
            amount = length * 2,
        }
        requirements.GlassPanel = {
            amount = length,
        }
    else
        requirements.SmallSheetMetal = {
            amount = length * 3,
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

function GarageBuild.getStock(character, containers)
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

function GarageBuild.hasRequirements(character, profile, length, containers)
    local requirements = GarageBuild.getRequirements(profile, length)
    if requirements == nil then
        return true
    end

    local stock = GarageBuild.getStock(character, containers)

    for key, requirement in pairs(requirements) do
        if getAvailableAmount(stock, key, requirement.uses) < requirement.amount then
            return false
        end
    end

    return true
end

function GarageBuild.getAvailable(character, key, uses, containers)
    local stock = GarageBuild.getStock(character, containers)
    return getAvailableAmount(stock, key, uses)
end

function GarageBuild.getRequirement(profile, length, fullType)
    local key = TYPE_TO_KEY[fullType]
    local requirements = GarageBuild.getRequirements(profile, length)

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

function GarageBuild.consumeExtras(
    character,
    profile,
    length,
    containers,
    vanillaBarCount
)
    local requirements = GarageBuild.getRequirements(profile, length)
    if requirements == nil then
        return true
    end

    local baseRequirements = isGlazed(profile)
        and BASE_REQUIREMENTS.glazed
        or BASE_REQUIREMENTS.solid
    local stock = GarageBuild.getStock(character, containers)
    local jobs = {}

    for key, requirement in pairs(requirements) do
        local amount = nil

        if key == "Bars" then
            amount = math.max(
                0,
                length - math.max(0, tonumber(vanillaBarCount) or 0)
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

function GarageBuild.recordExtras(buildObject)
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

function GarageBuild.createFaceProxy(face, length)
    if face == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)

    local width = face:getWidth()
    local height = face:getHeight()
    local horizontal = width > 1

    if not horizontal and height <= 1 then
        return face
    end

    local function mapCoordinates(x, y)
        local axis = horizontal and x or y
        local sourceSize = horizontal and width or height
        local mappedAxis = nil

        if axis <= 0 then
            mappedAxis = 0
        elseif axis >= length - 1 then
            mappedAxis = sourceSize - 1
        else
            mappedAxis = math.min(1, sourceSize - 1)
        end

        if horizontal then
            return mappedAxis, y
        end

        return x, mappedAxis
    end

    local proxy = {}

    function proxy:getFaceName()
        return face:getFaceName()
    end

    function proxy:getWidth()
        return horizontal and length or width
    end

    function proxy:getHeight()
        return horizontal and height or length
    end

    function proxy:getzLayers()
        return face:getzLayers()
    end

    function proxy:getMasterX()
        return face:getMasterX()
    end

    function proxy:getMasterY()
        return face:getMasterY()
    end

    function proxy:getMasterZ()
        return face:getMasterZ()
    end

    function proxy:isMasterSet()
        return face:isMasterSet()
    end

    function proxy:isMultiSquare()
        return face:isMultiSquare()
    end

    function proxy:getMasterTileInfo()
        return face:getMasterTileInfo()
    end

    function proxy:getTileInfoForSprite(tile)
        return face:getTileInfoForSprite(tile)
    end

    function proxy:getTileInfo(x, y, z)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:getTileInfo(mappedX, mappedY, z)
    end

    function proxy:verifyObject(x, y, z, object)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:verifyObject(mappedX, mappedY, z, object)
    end

    return proxy
end

return GarageBuild
