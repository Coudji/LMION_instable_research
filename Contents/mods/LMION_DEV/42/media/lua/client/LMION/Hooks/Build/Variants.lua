require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "BuildingObjects/ISBuildIsoEntity"
require "LMION/UI/Build/VariantSelector"

local VariantState = require "LMION/Services/Build/VariantState"

local function getEntityId(objectInfo)
    local spriteScript = objectInfo
        and objectInfo.getScript
        and objectInfo:getScript()
        or nil
    local gameScript = spriteScript
        and spriteScript.getParent
        and spriteScript:getParent()
        or nil

    if gameScript == nil then
        return nil
    end

    if gameScript.getFullName ~= nil then
        local fullName = gameScript:getFullName()
        if type(fullName) == "string" and fullName ~= "" then
            return fullName
        end
    end

    if gameScript.getName ~= nil then
        local name = gameScript:getName()
        if type(name) == "string" and name ~= "" then
            return "Base." .. name
        end
    end

    return nil
end

if not ISBuildRecipePanel._lmionV3VariantSelectorInstalled then
    ISBuildRecipePanel._lmionV3VariantSelectorInstalled = true

    local previousCreateDynamicChildren = ISBuildRecipePanel.createDynamicChildren

    ISBuildRecipePanel.createDynamicChildren = function(self)
        previousCreateDynamicChildren(self)

        local group = VariantState.getGroupFromLogic(self.logic)
        if group == nil or #group.members < 2 or self.rootTable == nil then
            self.lmionBuildVariantSelector = nil
            return
        end

        local selector = LMIONBuildVariantSelector:new(
            self.player,
            self.logic,
            self
        )
        selector:initialise()
        selector:instantiate()

        self.lmionBuildVariantSelector = selector
        self.rootTable:setElement(0, 1, selector)
        self:xuiRecalculateLayout()
    end
end

if not ISBuildPanel._lmionV3VariantBuildInstalled then
    ISBuildPanel._lmionV3VariantBuildInstalled = true

    local previousCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity

    ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
        local result = previousCreateBuildIsoEntity(self, dontSetDrag)
        local member = VariantState.getSelectedMember(self.logic)

        if member == nil or self.buildEntity == nil then
            return result
        end

        if getEntityId(self.buildEntity.objectInfo) == member.entityId then
            return result
        end

        local objectInfo = SpriteConfigManager.GetObjectInfo(member.recipeName)
        if objectInfo == nil then
            print(string.format(
                "[LMION:DEV] Build variant object info missing: definition=%s entity=%s",
                tostring(member.definitionId),
                tostring(member.entityId)
            ))
            return result
        end

        local previous = self.buildEntity
        local containers = ISInventoryPaneContextMenu.getContainers(self.player)
        local replacement = ISBuildIsoEntity:new(
            self.player,
            objectInfo,
            previous.nSprite or 1,
            containers,
            self.logic
        )

        replacement.dragNilAfterPlace = false
        replacement.blockAfterPlace = true
        replacement.blockBuild = previous.blockBuild
        replacement.equipBothHandItem = previous.equipBothHandItem
        replacement.firstItem = previous.firstItem
        replacement.secondItem = previous.secondItem

        self.buildEntity = replacement

        if not dontSetDrag then
            getCell():setDrag(replacement, self.player:getPlayerNum())
        end

        return result
    end
end

print("[LMION:DEV] Build variant hook installed")
