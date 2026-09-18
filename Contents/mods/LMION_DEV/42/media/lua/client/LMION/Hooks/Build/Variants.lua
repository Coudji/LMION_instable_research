require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "LMION/Hooks/Build/RecipeOptions"

local VariantState = require "LMION/Services/Build/VariantState"

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
