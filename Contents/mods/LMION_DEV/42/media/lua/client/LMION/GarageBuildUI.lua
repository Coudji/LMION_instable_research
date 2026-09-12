require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"

local GarageBuild = require "LMION/Services/Build/GarageLengthState"
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
    local length = GarageBuild.getLengthFromLogic(self.logic)
    local maximum = GarageLengthPolicy.getMaximumLength()

    self.value:setName(tostring(length))
    self.less.enable = length > GarageBuild.MinLength
    self.more.enable = maximum == nil or length < maximum
end

function LMIONGarageLengthSelector:setLength(length)
    if GarageBuild.setLengthOnLogic(self.logic, length) == nil then
        return
    end

    self:updateState()

    if self.panel ~= nil then
        self.panel:xuiRecalculateLayout()
    end
end

function LMIONGarageLengthSelector:onClick(button)
    local length = GarageBuild.getLengthFromLogic(self.logic)
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

local function getGarageContext(logic)
    local profile = GarageBuild.getProfileFromLogic(logic)
    if profile == nil then
        return nil, nil
    end

    return profile, GarageBuild.ensureLengthOnLogic(logic)
end

local function getContainers(logic)
    if logic == nil or logic.getContainers == nil then
        return nil
    end

    return logic:getContainers()
end

local previousCreateDynamicChildren = ISBuildRecipePanel.createDynamicChildren

ISBuildRecipePanel.createDynamicChildren = function(self)
    previousCreateDynamicChildren(self)

    local profile = getGarageContext(self.logic)
    if profile == nil or self.rootTable == nil then
        self.lmionGarageLengthSelector = nil
        return
    end

    local selector = LMIONGarageLengthSelector:new(
        self.player,
        self.logic,
        self
    )
    selector:initialise()
    selector:instantiate()

    self.lmionGarageLengthSelector = selector
    self.rootTable:setElement(0, 1, selector)
    self:xuiRecalculateLayout()
end

local function getInputFullType(widget)
    local inputScript = widget and widget.inputScript or nil
    local items = inputScript
        and inputScript.getPossibleInputItems
        and inputScript:getPossibleInputItems()
        or nil

    if items == nil or items:size() < 1 then
        return nil
    end

    return items:get(0):getFullName()
end

local previousInputUpdateValues = ISWidgetInput.updateValues

ISWidgetInput.updateValues = function(self)
    previousInputUpdateValues(self)

    local profile, length = getGarageContext(self.logic)
    if profile == nil
        or self.primary == nil
        or self.primary.label == nil then
        return
    end

    local fullType = getInputFullType(self)
    local requirement, key = GarageBuild.getRequirement(
        profile,
        length,
        fullType
    )

    if requirement == nil then
        return
    end

    local available = GarageBuild.getAvailable(
        self.player,
        key,
        requirement.uses,
        getContainers(self.logic)
    )
    local satisfied = available >= requirement.amount
    local text = nil

    if requirement.uses then
        local amountText = satisfied
            and tostring(requirement.amount)
            or tostring(available) .. "/" .. tostring(requirement.amount)

        text = amountText .. " " .. getText("Attributes_Type_Uses")
    else
        text = tostring(available) .. "/" .. tostring(requirement.amount)
    end

    self.primary.label:setName(text)
    self.primary.label.amountValue = requirement.amount
    self.primary.label.satisfiedValue = available

    if satisfied then
        self.primary.label.textColor = self.textColor
        self.borderColor = self.normalBorderColor
        self.primary.icon.backgroundColor.a = 1
    else
        self.primary.label.textColor = self.colBad
        self.borderColor = self.colBad

        if available <= 0 then
            self.primary.icon.backgroundColor.a = 0.25
        end
    end
end

local previousTitleUpdateLabels = ISWidgetTitleHeader.updateLabels

ISWidgetTitleHeader.updateLabels = function(self)
    previousTitleUpdateLabels(self)

    local profile, length = getGarageContext(self.logic)
    if profile == nil
        or self.errorLabel == nil
        or self.player:isBuildCheat() then
        return
    end

    local hasRequirements = GarageBuild.hasRequirements(
        self.player,
        profile,
        length,
        getContainers(self.logic)
    )
    local hasSelectedBars = GarageBuild.hasSelectedBars(self.logic, length)

    if not hasRequirements or not hasSelectedBars then
        local text = getText("IGUI_CraftingWindow_Error_NotAvailable")
            .. getText("IGUI_CraftingWindow_Error_Inputs")

        self.errorLabel.errorText = text
        self.errorLabel:setName(text)
        self.errorLabel:setVisible(true)
    end
end

local previousBuildControlPrerender = ISWidgetBuildControl.prerender

ISWidgetBuildControl.prerender = function(self)
    previousBuildControlPrerender(self)

    local profile, length = getGarageContext(self.logic)
    if profile == nil
        or self.buttonCraft == nil
        or self.player:isBuildCheat() then
        return
    end

    self.buttonCraft.enable = self.buttonCraft.enable
        and GarageBuild.hasRequirements(
            self.player,
            profile,
            length,
            getContainers(self.logic)
        )
        and GarageBuild.hasSelectedBars(self.logic, length)
end

local previousCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity

ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
    local profile, length = getGarageContext(self.logic)

    if profile ~= nil and self._lmionGarageRepeatLength ~= nil then
        length = GarageBuild.normalizeLength(self._lmionGarageRepeatLength)
    end

    local result = previousCreateBuildIsoEntity(self, dontSetDrag)

    if profile ~= nil and self.buildEntity ~= nil then
        self.buildEntity.lmionGarageLength = length
        self.buildEntity.lmionGarageDefinitionId = profile.definitionId

        if not self.player:isBuildCheat() then
            self.buildEntity.blockBuild = self.buildEntity.blockBuild
                or not GarageBuild.hasRequirements(
                    self.player,
                    profile,
                    length,
                    getContainers(self.logic)
                )
                or not GarageBuild.hasSelectedBars(self.logic, length)
        end
    end

    return result
end

local previousOnStopCraft = ISBuildPanel.onStopCraft

ISBuildPanel.onStopCraft = function(self)
    local profile, length = getGarageContext(self.logic)
    if profile == nil then
        return previousOnStopCraft(self)
    end

    self._lmionGarageRepeatLength = length
    local ok, result = pcall(previousOnStopCraft, self)
    self._lmionGarageRepeatLength = nil

    GarageBuild.setLengthOnLogic(self.logic, length)

    if self.buildEntity ~= nil then
        self.buildEntity.lmionGarageLength = length
    end

    local selector = self.craftRecipePanel
        and self.craftRecipePanel.lmionGarageLengthSelector
        or nil

    if selector ~= nil then
        selector:updateState()
    end

    if not ok then
        error(result)
    end

    return result
end
