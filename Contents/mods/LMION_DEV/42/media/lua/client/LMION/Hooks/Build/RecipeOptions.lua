require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "LMION/UI/Build/RecipeOptionsPanel"

if not ISBuildRecipePanel._lmionV3RecipeOptionsInstalled then
    ISBuildRecipePanel._lmionV3RecipeOptionsInstalled = true

    local previousCreateDynamicChildren = ISBuildRecipePanel.createDynamicChildren

    ISBuildRecipePanel.createDynamicChildren = function(self)
        previousCreateDynamicChildren(self)

        self.lmionBuildVariantSelector = nil
        self.lmionGarageWidthSelector = nil
        self.lmionBuildRecipeOptions = nil

        if self.rootTable == nil or self.logic:getRecipe() == nil then
            return
        end

        local options = LMIONBuildRecipeOptionsPanel:new(
            self.player,
            self.logic,
            self
        )
        options:initialise()
        options:instantiate()

        if not options:hasOptions() then
            return
        end

        self.lmionBuildRecipeOptions = options
        self.lmionBuildVariantSelector = options.variantSelector
        self.lmionGarageWidthSelector = options.garageWidthSelector

        self.rootTable:setElement(0, 1, options)
        self:xuiRecalculateLayout()
    end
end
