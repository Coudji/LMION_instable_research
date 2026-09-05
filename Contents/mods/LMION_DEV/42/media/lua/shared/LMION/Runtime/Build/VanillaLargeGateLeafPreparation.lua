local VanillaLargeGateLeafPreparation = {}

local SPECS = {
    {
        name = "DoubleDoor",
        expected = {
            "fixtures_doors_fences_01_96", "fixtures_doors_fences_01_97",
            "fixtures_doors_fences_01_98", "fixtures_doors_fences_01_99",
            "fixtures_doors_fences_01_104", "fixtures_doors_fences_01_105",
            "fixtures_doors_fences_01_106", "fixtures_doors_fences_01_107",
        },
        body = [[
entity DoubleDoor
{
    component SpriteConfig
    {
        dontNeedFrame = true,
        BreakSound = BreakDoor,
        face W { layer { row = fixtures_doors_fences_01_97, row = fixtures_doors_fences_01_96, } }
        face N { layer { row = fixtures_doors_fences_01_98 fixtures_doors_fences_01_99, } }
    }
}
]],
    },
    {
        name = "DoubleWireGate",
        expected = {
            "fixtures_doors_fences_01_64", "fixtures_doors_fences_01_65",
            "fixtures_doors_fences_01_66", "fixtures_doors_fences_01_67",
            "fixtures_doors_fences_01_72", "fixtures_doors_fences_01_73",
            "fixtures_doors_fences_01_74", "fixtures_doors_fences_01_75",
        },
        body = [[
entity DoubleWireGate
{
    component SpriteConfig
    {
        dontNeedFrame = true,
        BreakSound = BreakDoor,
        face W { layer { row = fixtures_doors_fences_01_65, row = fixtures_doors_fences_01_64, } }
        face N { layer { row = fixtures_doors_fences_01_66 fixtures_doors_fences_01_67, } }
    }
}
]],
    },
    {
        name = "DoubleFenceGate",
        expected = {
            "fixtures_doors_fences_01_80", "fixtures_doors_fences_01_81",
            "fixtures_doors_fences_01_82", "fixtures_doors_fences_01_83",
            "fixtures_doors_fences_01_88", "fixtures_doors_fences_01_89",
            "fixtures_doors_fences_01_90", "fixtures_doors_fences_01_91",
        },
        body = [[
entity DoubleFenceGate
{
    component SpriteConfig
    {
        dontNeedFrame = true,
        BreakSound = BreakDoor,
        face W { layer { row = fixtures_doors_fences_01_81, row = fixtures_doors_fences_01_80, } }
        face N { layer { row = fixtures_doors_fences_01_82 fixtures_doors_fences_01_83, } }
    }
}
]],
    },
}

local installed = false

local function makeSet(values)
    local result = {}
    for index = 1, #values do
        result[values[index]] = true
    end
    return result
end

local function hasExpectedTiles(spriteConfig, expectedValues)
    local expected = makeSet(expectedValues)
    local names = spriteConfig:getAllTileNames()
    if names:size() ~= #expectedValues then
        return false
    end

    for index = 0, names:size() - 1 do
        if not expected[tostring(names:get(index))] then
            return false
        end
    end

    return true
end

local function prepareSpec(spec)
    local script = ScriptManager.instance:getGameEntityScript("Base." .. spec.name)
    if script == nil then
        print("[LMION:DEV] LargeGate Build preparation failed: entity=" .. spec.name .. " reason=no-script")
        return false
    end

    local spriteConfig = script:getComponentScriptFor(ComponentType.SpriteConfig)
    if spriteConfig == nil or not hasExpectedTiles(spriteConfig, spec.expected) then
        print("[LMION:DEV] LargeGate Build preparation failed: entity=" .. spec.name .. " reason=unexpected-sprite-config")
        return false
    end

    spriteConfig:PreReload()
    local ok, reason = pcall(function()
        script:Load(spec.name, spec.body)
    end)
    if not ok then
        print("[LMION:DEV] LargeGate Build preparation failed: entity=" .. spec.name .. " reason=" .. tostring(reason))
        return false
    end

    print("[LMION:DEV] LargeGate Build leaf A prepared: entity=Base." .. spec.name)
    return true
end

function VanillaLargeGateLeafPreparation.prepare()
    if ScriptManager == nil or ScriptManager.instance == nil or ComponentType == nil then
        return false
    end

    for index = 1, #SPECS do
        if not prepareSpec(SPECS[index]) then
            return false
        end
    end

    return true
end

function VanillaLargeGateLeafPreparation.install()
    if installed or Events == nil or Events.OnGameBoot == nil then
        return false
    end

    installed = true
    Events.OnGameBoot.Add(VanillaLargeGateLeafPreparation.prepare)
    return true
end

return VanillaLargeGateLeafPreparation
