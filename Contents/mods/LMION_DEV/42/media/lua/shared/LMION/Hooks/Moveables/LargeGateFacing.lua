require "Moveables/ISMoveableSpriteProps"

local LargeGateMoveProps = require "LMION/Services/Moveables/LargeGateMoveProps"

local LargeGateFacingHook = {}

function LargeGateFacingHook.install()
    if ISMoveableSpriteProps._lmionV3LargeGateFacingInstalled == true then
        return false
    end

    ISMoveableSpriteProps._lmionV3LargeGateFacingInstalled = true

    local previousGetIndexedFaces = ISMoveableSpriteProps.getIndexedFaces
    local previousGetFaceIndex = ISMoveableSpriteProps.getFaceIndex

    ISMoveableSpriteProps.getIndexedFaces = function(self)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment ~= nil then
            local faces = self:getFaces()
            return { faces.N, faces.W, faces.N, faces.W }
        end

        return previousGetIndexedFaces(self)
    end

    ISMoveableSpriteProps.getFaceIndex = function(self)
        local segment = LargeGateMoveProps.getSegment(self)
        if segment ~= nil then
            if self.lmionLargeGateFacing == "N" then
                return 1
            end
            if self.lmionLargeGateFacing == "W" then
                return 2
            end
            return -1
        end

        return previousGetFaceIndex(self)
    end

    print("[LMION:DEV] LargeGate facing hooks installed")
    return true
end

return LargeGateFacingHook
