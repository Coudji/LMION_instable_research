local GarageWidthPolicy = {}

GarageWidthPolicy.MinimumWidth = 2
GarageWidthPolicy.DefaultMaximumWidth = 6
GarageWidthPolicy.MinimumConfigurableMaximumWidth = 6
GarageWidthPolicy.MaximumConfigurableWidth = 12

local function getSandboxOptions()
    if SandboxVars == nil then
        return nil
    end

    return SandboxVars.LMION
end

function GarageWidthPolicy.getMaximumWidth()
    local options = getSandboxOptions()
    if options ~= nil and options.UnlimitedGarageWidth == true then
        return nil
    end

    local maximum = options and tonumber(options.GarageMaxWidth) or nil
    if maximum == nil then
        maximum = GarageWidthPolicy.DefaultMaximumWidth
    end

    maximum = math.floor(maximum)
    return math.max(
        GarageWidthPolicy.MinimumConfigurableMaximumWidth,
        math.min(maximum, GarageWidthPolicy.MaximumConfigurableWidth)
    )
end

function GarageWidthPolicy.isWidthAllowed(width)
    width = tonumber(width)
    if width == nil or width < GarageWidthPolicy.MinimumWidth then
        return false
    end

    local maximum = GarageWidthPolicy.getMaximumWidth()
    return maximum == nil or width <= maximum
end

return GarageWidthPolicy
