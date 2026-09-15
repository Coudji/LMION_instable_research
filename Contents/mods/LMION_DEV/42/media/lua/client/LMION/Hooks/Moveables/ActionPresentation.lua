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

local function playPresentationSound(action, soundName)
    local character = action and action.character or nil
    if character == nil or soundName == nil then
        return nil
    end

    addSound(
        character,
        character:getX(),
        character:getY(),
        character:getZ(),
        10,
        5
    )

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
        if presentation == nil or presentation.sound == nil then
            return originalSetActionSound(self)
        end

        self.sound = playPresentationSound(self, presentation.sound)
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
