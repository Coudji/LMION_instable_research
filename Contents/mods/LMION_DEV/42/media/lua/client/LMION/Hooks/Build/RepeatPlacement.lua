require "Entity/ISUI/BuildRecipe/ISBuildPanel"

local GarageBuild = require "LMION/Services/Build/Garage/Build"
local GarageWidthState = require "LMION/Services/Build/Garage/WidthState"
local VariantState = require "LMION/Services/Build/VariantState"

local function getGarageState(panel)
    local profile = GarageBuild.getProfileFromLogic(panel.logic)
    if profile == nil then
        return nil, nil
    end

    return profile, GarageWidthState.ensureWidthOnLogic(panel.logic)
end

local function restoreGarageWidth(panel, profile, width)
    if profile == nil or width == nil then
        return
    end

    GarageWidthState.setWidthOnLogic(panel.logic, width)

    if panel.buildEntity ~= nil then
        panel.buildEntity.lmionGarageWidth = width
    end

    local selector = panel.craftRecipePanel
        and panel.craftRecipePanel.lmionGarageWidthSelector
        or nil

    if selector ~= nil then
        selector:updateState()
    end
end

local function restoreVariant(panel, member)
    if member == nil then
        return false
    end

    local restored = VariantState.setSelectedDefinitionId(
        panel.logic,
        member.definitionId
    )

    if restored == nil then
        return false
    end

    panel:createBuildIsoEntity()
    panel:updateManualInputs()
    return true
end

if not ISBuildPanel._lmionV3RepeatPlacementInstalled then
    ISBuildPanel._lmionV3RepeatPlacementInstalled = true

    local previousOnStopCraft = ISBuildPanel.onStopCraft

    ISBuildPanel.onStopCraft = function(self)
        local variantMember = VariantState.getSelectedMember(self.logic)
        local garageProfile, garageWidth = getGarageState(self)

        if garageProfile ~= nil then
            self._lmionGarageRepeatWidth = garageWidth
        end

        local ok, result = pcall(previousOnStopCraft, self)
        self._lmionGarageRepeatWidth = nil

        restoreGarageWidth(self, garageProfile, garageWidth)
        restoreVariant(self, variantMember)

        if not ok then
            error(result)
        end

        return result
    end
end
