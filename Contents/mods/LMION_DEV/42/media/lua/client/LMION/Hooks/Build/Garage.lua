require "Entity/ISUI/BuildRecipe/ISWidgetBuildControl"
require "Entity/ISUI/CraftRecipe/ISWidgetInput"
require "Entity/ISUI/BuildRecipe/ISBuildPanel"
require "Entity/ISUI/Controls/ISWidgetTitleHeader"
require "LMION/Hooks/Build/RecipeOptions"
require "LMION/Hooks/Build/RepeatPlacement"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageRequirements = require "LMION/Services/Build/Garage/Requirements"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"

local function getGarageContext(logic)
    local profile = GarageBuild.getProfileFromLogic(logic)
    if profile == nil then
        return nil, nil
    end

    return profile, GarageWidthState.ensureWidthOnLogic(logic)
end

local function getContainers(logic)
    return logic and logic.getContainers and logic:getContainers() or nil
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

    local profile, width = getGarageContext(self.logic)
    if profile == nil
        or self.primary == nil
        or self.primary.label == nil then
        return
    end

    local fullType = getInputFullType(self)
    local requirement = GarageRequirements.getRequirement(profile, width, fullType)
    if requirement == nil then
        return
    end

    local available = GarageRequirements.getAvailable(
        self.player,
        profile,
        width,
        requirement,
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

    local profile, width = getGarageContext(self.logic)
    if profile == nil
        or self.errorLabel == nil
        or self.player:isBuildCheat() then
        return
    end

    local hasRequirements = GarageRequirements.hasRequirements(
        self.player,
        profile,
        width,
        getContainers(self.logic)
    )
    local hasSelectedWidthInputs = GarageWidthState.hasSelectedWidthInputs(
        self.logic,
        width
    )

    if not hasRequirements or not hasSelectedWidthInputs then
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

    local profile, width = getGarageContext(self.logic)
    if profile == nil
        or self.buttonCraft == nil
        or self.player:isBuildCheat() then
        return
    end

    self.buttonCraft.enable = self.buttonCraft.enable
        and GarageRequirements.hasRequirements(
            self.player,
            profile,
            width,
            getContainers(self.logic)
        )
        and GarageWidthState.hasSelectedWidthInputs(self.logic, width)
end

local previousCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity

ISBuildPanel.createBuildIsoEntity = function(self, dontSetDrag)
    local profile, width = getGarageContext(self.logic)

    if profile ~= nil and self._lmionGarageRepeatWidth ~= nil then
        width = GarageBuild.normalizeWidth(self._lmionGarageRepeatWidth)
    end

    local result = previousCreateBuildIsoEntity(self, dontSetDrag)

    if profile ~= nil and self.buildEntity ~= nil then
        self.buildEntity.lmionGarageWidth = width
        self.buildEntity.lmionGarageDefinitionId = profile.definitionId

        if not self.player:isBuildCheat() then
            self.buildEntity.blockBuild = self.buildEntity.blockBuild
                or not GarageRequirements.hasRequirements(
                    self.player,
                    profile,
                    width,
                    getContainers(self.logic)
                )
                or not GarageWidthState.hasSelectedWidthInputs(
                    self.logic,
                    width
                )
        end
    end

    return result
end
