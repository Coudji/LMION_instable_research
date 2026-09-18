require "ISUI/ISPanel"
require "LMION/UI/Build/GarageWidthSelector"
require "LMION/UI/Build/VariantSelector"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"
local VariantState = require "LMION/Services/Build/VariantState"

LMIONBuildRecipeOptionsPanel = ISPanel:derive("LMIONBuildRecipeOptionsPanel")

function LMIONBuildRecipeOptionsPanel:initialise()
    ISPanel.initialise(self)
end

local function initialiseChild(panel, child)
    child:initialise()
    child:instantiate()
    panel:addChild(child)
    panel.controls[#panel.controls + 1] = child
end

function LMIONBuildRecipeOptionsPanel:createChildren()
    ISPanel.createChildren(self)

    self.controls = {}

    local group = VariantState.getGroupFromLogic(self.logic)
    if group ~= nil and #group.members > 1 then
        self.variantSelector = LMIONBuildVariantSelector:new(
            self.player,
            self.logic,
            self.recipePanel
        )
        initialiseChild(self, self.variantSelector)
    end

    local garageProfile = GarageBuild.getProfileFromLogic(self.logic)
    if garageProfile ~= nil then
        GarageWidthState.ensureWidthOnLogic(self.logic)

        self.garageWidthSelector = LMIONGarageWidthSelector:new(
            self.player,
            self.logic,
            self.recipePanel
        )
        initialiseChild(self, self.garageWidthSelector)
    end
end

function LMIONBuildRecipeOptionsPanel:hasOptions()
    return #self.controls > 0
end

function LMIONBuildRecipeOptionsPanel:calculateLayout(panelWidth, panelHeight)
    panelWidth = math.max(panelWidth or 0, 240)

    local y = 0
    for index = 1, #self.controls do
        local control = self.controls[index]
        control:calculateLayout(panelWidth, 0)
        control:setX(0)
        control:setY(y)
        y = y + control:getHeight()
    end

    self:setWidth(panelWidth)
    self:setHeight(math.max(panelHeight or 0, y))
end

function LMIONBuildRecipeOptionsPanel:new(player, logic, recipePanel)
    local o = ISPanel:new(0, 0, 240, 0)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic
    o.recipePanel = recipePanel
    o.background = false
    o.controls = {}

    return o
end

return LMIONBuildRecipeOptionsPanel
