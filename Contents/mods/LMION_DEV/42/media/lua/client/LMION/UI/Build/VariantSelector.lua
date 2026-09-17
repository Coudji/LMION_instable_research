require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"

local VariantGroups = require "LMION/Services/Build/VariantGroups"
local VariantState = require "LMION/Services/Build/VariantState"

local CONTROL_HEIGHT = getTextManager():getFontHeight(UIFont.Small) + 8

LMIONBuildVariantSelector = ISPanel:derive("LMIONBuildVariantSelector")

function LMIONBuildVariantSelector:initialise()
    ISPanel.initialise(self)
end

function LMIONBuildVariantSelector:createChildren()
    ISPanel.createChildren(self)

    self.label = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        getText("IGUI_LMION_BuildVariant_Model"),
        1,
        1,
        1,
        1,
        UIFont.Small,
        true
    )
    self.label:initialise()
    self.label:instantiate()
    self:addChild(self.label)

    self.previous = ISButton:new(
        0,
        0,
        CONTROL_HEIGHT,
        CONTROL_HEIGHT,
        "<",
        self,
        LMIONBuildVariantSelector.onClick
    )
    self.previous:initialise()
    self.previous:instantiate()
    self:addChild(self.previous)

    self.value = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        "",
        1,
        1,
        1,
        1,
        UIFont.Small,
        true
    )
    self.value:initialise()
    self.value:instantiate()
    self:addChild(self.value)

    self.next = ISButton:new(
        0,
        0,
        CONTROL_HEIGHT,
        CONTROL_HEIGHT,
        ">",
        self,
        LMIONBuildVariantSelector.onClick
    )
    self.next:initialise()
    self.next:instantiate()
    self:addChild(self.next)

    self:updateState()
end

local function getMemberDisplayName(member)
    local recipe = VariantGroups.getRecipeForMember(member)
    if recipe ~= nil and recipe.getTranslationName ~= nil then
        return recipe:getTranslationName()
    end

    return member and member.definitionId or "?"
end

function LMIONBuildVariantSelector:updateState()
    local group = VariantState.getGroupFromLogic(self.logic)
    local member = VariantState.getSelectedMember(self.logic)

    if group == nil or member == nil then
        self.value:setName("")
        self.previous.enable = false
        self.next.enable = false
        return
    end

    self.value:setName(getMemberDisplayName(member))
    local canSwitch = #group.members > 1
    self.previous.enable = canSwitch
    self.next.enable = canSwitch
end

function LMIONBuildVariantSelector:onClick(button)
    local delta = button == self.previous and -1 or 1
    local member = VariantState.selectRelative(self.logic, delta)
    if member == nil then
        return
    end

    self:updateState()

    local buildPanel = ISBuildWindow and ISBuildWindow.instance or nil
    if buildPanel ~= nil and buildPanel.logic == self.logic then
        buildPanel:createBuildIsoEntity()
        buildPanel:updateManualInputs()
    end

    if self.panel ~= nil then
        self.panel:xuiRecalculateLayout()
    end
end

function LMIONBuildVariantSelector:calculateLayout(panelWidth, panelHeight)
    panelWidth = math.max(panelWidth or 0, 240)
    panelHeight = math.max(panelHeight or 0, CONTROL_HEIGHT + 16)

    local x = 8
    local y = 8

    self.label:setX(x)
    self.label:setY(y)

    x = self.label:getRight() + 8
    self.previous:setX(x)
    self.previous:setY(y)

    x = self.previous:getRight() + 8
    self.value:setX(x)
    self.value:setY(y)

    x = self.value:getRight() + 8
    self.next:setX(x)
    self.next:setY(y)

    self:setWidth(panelWidth)
    self:setHeight(panelHeight)
end

function LMIONBuildVariantSelector:new(player, logic, panel)
    local o = ISPanel:new(0, 0, 240, CONTROL_HEIGHT + 16)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic
    o.panel = panel
    o.background = false

    return o
end

return LMIONBuildVariantSelector
