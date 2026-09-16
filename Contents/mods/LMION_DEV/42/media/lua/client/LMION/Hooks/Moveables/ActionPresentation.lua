require "Moveables/ISMoveablesAction"

local PresentationPolicy = require "LMION/Services/Moveables/ActionPresentation"

local ActionPresentationHook = {}

local function resolve(action)
    return PresentationPolicy.resolve(
        action and action.moveProps or nil,
        action and action.mode or nil
    )
end

local function getResolvedTool(action)
    local moveProps = action and action.moveProps or nil
    local character = action and action.character or nil
    local mode = action and action.mode or nil

    if moveProps == nil
        or character == nil
        or (mode ~= "pickup" and mode ~= "place") then
        return nil
    end

    local tool = moveProps:hasTool(character, mode)
    if tool == nil or tool == false or tool == true then
        return nil
    end

    return tool
end

local function equipResolvedTool(character, tool)
    if character == nil or tool == nil then
        return
    end

    local oldPrimary = character:getPrimaryHandItem()
    local oldSecondary = character:getSecondaryHandItem()

    if oldSecondary == oldPrimary and oldPrimary ~= tool then
        character:setSecondaryHandItem(nil)
    end

    if oldPrimary ~= tool then
        character:setPrimaryHandItem(tool)
    end
end

local function emitWorldNoise(action, presentation)
    local character = action and action.character or nil
    local noise = presentation and presentation.worldNoise or nil
    if character == nil or noise == nil then
        return
    end

    local radius = tonumber(noise.radius) or 0
    local volume = tonumber(noise.volume) or 0
    if radius <= 0 or volume <= 0 then
        return
    end

    addSound(
        character,
        character:getX(),
        character:getY(),
        character:getZ(),
        radius,
        volume
    )
end

local function playPresentationSound(action, presentation)
    local character = action and action.character or nil
    local soundName = presentation and presentation.sound or nil
    if character == nil or soundName == nil then
        return nil
    end

    emitWorldNoise(action, presentation)
    return character:playSound(soundName)
end

function ActionPresentationHook.install()
    if ISMoveablesAction._lmionV3PresentationInstalled == true then
        return false
    end

    ISMoveablesAction._lmionV3PresentationInstalled = true

    local originalStart = ISMoveablesAction.start
    local originalSetActionSound = ISMoveablesAction.setActionSound

    ISMoveablesAction.setActionSound = function(self)
        local presentation = resolve(self)
        if presentation == nil then
            return originalSetActionSound(self)
        end

        if presentation.sound ~= nil then
            self.sound = playPresentationSound(self, presentation)
            return
        end

        -- Screwdriver keeps PZ's configured audio but must not inherit the
        -- vanilla Moveables 10/5 WorldSound. Reproduce only the audible tool
        -- sound here; LMION's policy intentionally emits no zombie attraction.
        if presentation.toolKind == "screwdriver" then
            local moveProps = self.moveProps
            local mode = self.mode
            local toolName = nil
            if moveProps ~= nil then
                toolName = mode == "pickup" and moveProps.pickUpTool
                    or mode == "place" and moveProps.placeTool
                    or nil
            end

            local toolDef = toolName
                and ISMoveableDefinitions:getInstance().getToolDefinition(toolName)
                or nil

            if toolDef ~= nil and toolDef.sound ~= nil then
                self.sound = self.character:playSound(toolDef.sound)
                return
            end

            self.sound = nil
            return
        end

        return originalSetActionSound(self)
    end

    ISMoveablesAction.start = function(self)
        local presentation = resolve(self)
        if presentation == nil then
            return originalStart(self)
        end

        local tool = getResolvedTool(self)

        -- walkToAndEquip() still owns pathing and inventory validation. At action
        -- start, make the already-resolved gameplay tool authoritative for the
        -- hand model so the previous Moveables action cannot leak its tool into
        -- the next animation.
        equipResolvedTool(self.character, tool)

        originalStart(self)

        if presentation.animation ~= nil then
            self:setActionAnim(presentation.animation)
        end

        if tool ~= nil then
            self:setOverrideHandModels(tool, nil)
        end
    end

    print("[LMION:DEV] Moveables action presentation hook installed")
    return true
end

ActionPresentationHook.install()

return ActionPresentationHook
