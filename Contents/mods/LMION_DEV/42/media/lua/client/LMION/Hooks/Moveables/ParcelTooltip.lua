require "ISUI/ISToolTipInv"

local DoorTransportState = require "LMION/Runtime/Moveables/DoorTransportState"

local ParcelTooltip = {}

local function roundHealth(value)
    return math.max(0, math.floor(value + 0.5))
end

local function getHealthState(item)
    local state = DoorTransportState.readFromItem(item)
    if state == nil
        or type(state.health) ~= "number"
        or type(state.maxHealth) ~= "number" then
        return nil
    end

    return {
        health = roundHealth(state.health),
        maxHealth = roundHealth(state.maxHealth),
    }
end

local function renderItemTooltip(item, tooltip, state)
    -- InventoryItem:DoTooltipEmbedded() draws the normal item header and fills
    -- the supplied vanilla Layout without rendering it. This lets LMION append
    -- one ordinary row instead of drawing a second custom tooltip panel.
    local layout = tooltip:beginLayout()
    layout:setMinLabelWidth(80)
    layout:setMinValueWidth(80)

    item:DoTooltipEmbedded(tooltip, layout, 0)

    local row = layout:addItem()
    row:setLabel(
        getText("IGUI_LMION_ParcelHealth")
            .. " : "
            .. tostring(state.health)
            .. "/"
            .. tostring(state.maxHealth),
        1.0,
        1.0,
        0.8,
        1.0
    )

    -- LMION transport parcels are simple inventory items: their vanilla layout
    -- begins immediately below the standard item-name row.
    local y = (tooltip.padTop or 5) + tooltip:getLineSpacing() + 5
    y = layout:render(tooltip.padLeft or 5, y, tooltip)
    tooltip:endLayout(layout)

    y = y + (tooltip.padBottom or 5)
    tooltip:setHeight(y)
    if tooltip:getWidth() < 150 then
        tooltip:setWidth(150)
    end
end

local function renderParcelTooltip(self, state)
    -- Keep PZ's inventory-tooltip positioning and sizing behavior intact; only
    -- replace the two DoTooltip() calls with the embedded-layout variant above.
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    local padX = 0

    self.tooltip:setX(mx + padX)
    self.tooltip:setY(my)

    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    renderItemTooltip(self.item, self.tooltip, state)
    self.tooltip:setMeasureOnly(false)

    local core = getCore()
    local maxX = core:getScreenWidth()
    local maxY = core:getScreenHeight()
    local width = self.tooltip:getWidth()
    local height = self.tooltip:getHeight()

    self.tooltip:setX(math.max(0, math.min(mx + padX, maxX - width - 1)))
    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - height, maxY - height - 1)))
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - height - 1)))
    end

    if self.contextMenu and self.contextMenu.joyfocus then
        local playerNum = self.contextMenu.player
        self.tooltip:setX(getPlayerScreenLeft(playerNum) + 60)
        self.tooltip:setY(getPlayerScreenTop(playerNum) + 60)
    elseif self.contextMenu and self.contextMenu.currentOptionRect then
        if self.contextMenu.currentOptionRect.height > 32 then
            self:setY(my + self.contextMenu.currentOptionRect.height)
        end
        self:adjustPositionToAvoidOverlap(self.contextMenu.currentOptionRect)
    end

    self:setX(self.tooltip:getX() - padX)
    self:setY(self.tooltip:getY())
    self:setWidth(width + padX)
    self:setHeight(height)

    if self.followMouse and self.contextMenu == nil then
        self:adjustPositionToAvoidOverlap({
            x = mx - 24 * 2,
            y = my - 24 * 2,
            width = 24 * 2,
            height = 24 * 2,
        })
    end

    self:drawRect(
        0,
        0,
        self.width,
        self.height,
        self.backgroundColor.a,
        self.backgroundColor.r,
        self.backgroundColor.g,
        self.backgroundColor.b
    )
    self:drawRectBorder(
        0,
        0,
        self.width,
        self.height,
        self.borderColor.a,
        self.borderColor.r,
        self.borderColor.g,
        self.borderColor.b
    )

    renderItemTooltip(self.item, self.tooltip, state)
end

function ParcelTooltip.install()
    if ISToolTipInv._lmionV3ParcelHealthInstalled == true then
        return false
    end

    ISToolTipInv._lmionV3ParcelHealthInstalled = true

    local originalRender = ISToolTipInv.render
    ISToolTipInv.render = function(self)
        local state = self.item and getHealthState(self.item) or nil
        if state == nil then
            return originalRender(self)
        end

        return renderParcelTooltip(self, state)
    end

    print("[LMION:DEV] parcel health tooltip hook installed")
    return true
end

ParcelTooltip.install()

return ParcelTooltip
