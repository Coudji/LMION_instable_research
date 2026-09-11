local GarageLengthPolicy = {}

GarageLengthPolicy.MinimumLength = 2
GarageLengthPolicy.DefaultMaximumLength = 6
GarageLengthPolicy.ConfigurableMinimumMaximum = 6
GarageLengthPolicy.ConfigurableMaximumMaximum = 12

local function getSandboxOptions()
    if SandboxVars == nil then
        return nil
    end
    return SandboxVars.LMION
end

function GarageLengthPolicy.getMaximumLength()
    local options = getSandboxOptions()
    if options ~= nil and options.UnlimitedGarageWidth == true then
        return nil
    end

    local maximum = options and tonumber(options.GarageMaxLength) or nil
    if maximum == nil then
        maximum = GarageLengthPolicy.DefaultMaximumLength
    end

    maximum = math.floor(maximum)
    return math.max(
        GarageLengthPolicy.ConfigurableMinimumMaximum,
        math.min(maximum, GarageLengthPolicy.ConfigurableMaximumMaximum)
    )
end

function GarageLengthPolicy.isLengthAllowed(length)
    length = tonumber(length)
    if length == nil or length < GarageLengthPolicy.MinimumLength then
        return false
    end

    local maximum = GarageLengthPolicy.getMaximumLength()
    return maximum == nil or length <= maximum
end

return GarageLengthPolicy
