require "Entity/ISUI/BuildRecipe/ISBuildRecipePanel"
require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"
require "LMION/UI/Build/GarageLengthSelector"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"
local GarageLengthState = require "LMION/Services/Build/Garage/LengthState"

local function getGarageContext(logic)
    local profile = GarageBuild.getProfileFromLogic(logic)
    if profile == nil then
        return nil, nil
    end

    return profile, GarageLengthState.ensureLengthOnLogic(logic)
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
    local requirement, key = GarageRequirements.getRequirement(
        profile,
        length,
        fullType
    )

    if requirement == nil then
        return
    end

    local available = GarageRequirements.getAvailable(
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

    local hasRequirements = GarageRequirements.hasRequirements(
        self.player,
        profile,
        length,
        getContainers(self.logic)
    )
    local hasSelectedBars = GarageLengthState.hasSelectedBars(self.logic, length)

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
        and GarageRequirements.hasRequirements(
            self.player,
            profile,
            length,
            getContainers(self.logic)
        )
        and GarageLengthState.hasSelectedBars(self.logic, length)
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
                or not GarageRequirements.hasRequirements(
                    self.player,
                    profile,
                    length,
                    getContainers(self.logic)
                )
                or not GarageLengthState.hasSelectedBars(self.logic, length)
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

    GarageLengthState.setLengthOnLogic(self.logic, length)

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
