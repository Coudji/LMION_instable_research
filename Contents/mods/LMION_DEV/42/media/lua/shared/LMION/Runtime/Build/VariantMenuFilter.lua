local VariantGroups = require "LMION/Services/Build/VariantGroups"

local VariantMenuFilter = {}
local installed = false

function VariantMenuFilter.install()
    if installed then
        return false
    end

    installed = true

    function LMIONBuildVariantOnAddToMenu(params)
        local recipe = params and params.recipe or nil
        return VariantGroups.shouldShowRecipe(recipe)
    end

    return true
end

return VariantMenuFilter
