require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "LMION/UI/Build/VariantSelector"

local VariantState = require "LMION/Services/Build/VariantState"

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

if not ISBuildPanel._lmionV3VariantRepeatInstalled then
    ISBuildPanel._lmionV3VariantRepeatInstalled = true

    local previousOnStopCraft = ISBuildPanel.onStopCraft

    ISBuildPanel.onStopCraft = function(self)
        local member = VariantState.getSelectedMember(self.logic)
        local result = previousOnStopCraft(self)

        if member == nil then
            return result
        end

        local restored = VariantState.setSelectedDefinitionId(
            self.logic,
            member.definitionId
        )
        if restored == nil then
            return result
        end

        self:createBuildIsoEntity()
        self:updateManualInputs()

        return result
    end
end
