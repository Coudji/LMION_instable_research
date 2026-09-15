require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageLengthState = require "LMION/Services/Build/Garage/LengthState"
local GarageLengthPolicy = require "LMION/Domain/GarageLengthPolicy"

local CONTROL_HEIGHT = getTextManager():getFontHeight(UIFont.Small) + 8

LMIONGarageLengthSelector = ISPanel:derive("LMIONGarageLengthSelector")

function LMIONGarageLengthSelector:initialise()
    ISPanel.initialise(self)
end

function LMIONGarageLengthSelector:createChildren()
    ISPanel.createChildren(self)

    self.label = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        getText("IGUI_LMION_GarageBuild_Length"),
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
        LMIONGarageLengthSelector.onClick
    )
    self.less:initialise()
    self.less:instantiate()
    self:addChild(self.less)

    self.value = ISLabel:new(
        0,
        0,
        CONTROL_HEIGHT,
        tostring(GarageBuild.DefaultLength),
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
        LMIONGarageLengthSelector.onClick
    )
    self.more:initialise()
    self.more:instantiate()
    self:addChild(self.more)

    self:updateState()
end

function LMIONGarageLengthSelector:updateState()
    local length = GarageLengthState.getLengthFromLogic(self.logic)
    local maximum = GarageLengthPolicy.getMaximumLength()

    self.value:setName(tostring(length))
    self.less.enable = length > GarageBuild.MinLength
    self.more.enable = maximum == nil or length < maximum
end

function LMIONGarageLengthSelector:setLength(length)
    if GarageLengthState.setLengthOnLogic(self.logic, length) == nil then
        return
    end

    self:updateState()

    if self.panel ~= nil then
        self.panel:xuiRecalculateLayout()
    end
end

function LMIONGarageLengthSelector:onClick(button)
    local length = GarageLengthState.getLengthFromLogic(self.logic)
    local delta = button == self.less and -1 or 1

    self:setLength(length + delta)
end

function LMIONGarageLengthSelector:calculateLayout(width, height)
    width = math.max(width or 0, 180)
    height = math.max(height or 0, CONTROL_HEIGHT + 16)

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

    self:setWidth(width)
    self:setHeight(height)
end

function LMIONGarageLengthSelector:new(player, logic, panel)
    local o = ISPanel:new(0, 0, 180, CONTROL_HEIGHT + 16)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic
    o.panel = panel
    o.background = false

    return o
end

return LMIONGarageLengthSelector
