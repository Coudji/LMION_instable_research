require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"
local GarageWidthPolicy = require "LMION/Domain/GarageWidthPolicy"

local CONTROL_HEIGHT = getTextManager():getFontHeight(UIFont.Small) + 8

LMIONGarageWidthSelector = ISPanel:derive("LMIONGarageWidthSelector")

function LMIONGarageWidthSelector:initialise()
    ISPanel.initialise(self)
end

function LMIONGarageWidthSelector:createChildren()
    ISPanel.createChildren(self)

    self.label = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        getText("IGUI_LMION_GarageBuild_Width"),
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

    self.less = ISButton:new(
        0,
        0,
        CONTROL_HEIGHT,
        CONTROL_HEIGHT,
        "-",
        self,
        LMIONGarageWidthSelector.onClick
    )
    self.less:initialise()
    self.less:instantiate()
    self:addChild(self.less)

    self.value = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        tostring(GarageBuild.DefaultWidth),
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

    self.more = ISButton:new(
        0,
        0,
        CONTROL_HEIGHT,
        CONTROL_HEIGHT,
        "+",
        self,
        LMIONGarageWidthSelector.onClick
    )
    self.more:initialise()
    self.more:instantiate()
    self:addChild(self.more)

    self:updateState()
end

function LMIONGarageWidthSelector:updateState()
    local width = GarageWidthState.getWidthFromLogic(self.logic)
    local maximum = GarageWidthPolicy.getMaximumWidth()

    self.value:setName(tostring(width))
    self.less.enable = width > GarageBuild.MinWidth
    self.more.enable = maximum == nil or width < maximum
end

function LMIONGarageWidthSelector:setGarageWidth(width)
    if GarageWidthState.setWidthOnLogic(self.logic, width) == nil then
        return
    end

    self:updateState()

    if self.panel ~= nil then
        self.panel:xuiRecalculateLayout()
    end
end

function LMIONGarageWidthSelector:onClick(button)
    local width = GarageWidthState.getWidthFromLogic(self.logic)
    local delta = button == self.less and -1 or 1

    self:setGarageWidth(width + delta)
end

function LMIONGarageWidthSelector:calculateLayout(panelWidth, panelHeight)
    panelWidth = math.max(panelWidth or 0, 180)
    panelHeight = math.max(panelHeight or 0, CONTROL_HEIGHT + 16)

    local x = 8
    local y = 8

    self.label:setX(x)
    self.label:setY(y)

    x = self.label:getRight() + 8
    self.less:setX(x)
    self.less:setY(y)

    x = self.less:getRight() + 8
    self.value:setX(x)
    self.value:setY(y)

    x = x + 32
    self.more:setX(x)
    self.more:setY(y)

    self:setWidth(panelWidth)
    self:setHeight(panelHeight)
end

function LMIONGarageWidthSelector:new(player, logic, panel)
    local o = ISPanel:new(0, 0, 180, CONTROL_HEIGHT + 16)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic
    o.panel = panel
    o.background = false

    return o
end

return LMIONGarageWidthSelector
