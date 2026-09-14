local GarageBuild = require "LMION/Services/Build/Garage/GarageBuild"

local GarageBuildFaceProxy = {}

function GarageBuildFaceProxy.create(face, length)
    if face == nil then
        return nil
    end

    length = GarageBuild.normalizeLength(length)

    local width = face:getWidth()
    local height = face:getHeight()
    local horizontal = width > 1

    if not horizontal and height <= 1 then
        return face
    end

    local function mapCoordinates(x, y)
        local axis = horizontal and x or y
        local sourceSize = horizontal and width or height
        local mappedAxis = nil

        if axis <= 0 then
            mappedAxis = 0
        elseif axis >= length - 1 then
            mappedAxis = sourceSize - 1
        else
            mappedAxis = math.min(1, sourceSize - 1)
        end

        if horizontal then
            return mappedAxis, y
        end

        return x, mappedAxis
    end

    local proxy = {}

    function proxy:getFaceName()
        return face:getFaceName()
    end

    function proxy:getWidth()
        return horizontal and length or width
    end

    function proxy:getHeight()
        return horizontal and height or length
    end

    function proxy:getzLayers()
        return face:getzLayers()
    end

    function proxy:getMasterX()
        return face:getMasterX()
    end

    function proxy:getMasterY()
        return face:getMasterY()
    end

    function proxy:getMasterZ()
        return face:getMasterZ()
    end

    function proxy:isMasterSet()
        return face:isMasterSet()
    end

    function proxy:isMultiSquare()
        return face:isMultiSquare()
    end

    function proxy:getMasterTileInfo()
        return face:getMasterTileInfo()
    end

    function proxy:getTileInfoForSprite(tile)
        return face:getTileInfoForSprite(tile)
    end

    function proxy:getTileInfo(x, y, z)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:getTileInfo(mappedX, mappedY, z)
    end

    function proxy:verifyObject(x, y, z, object)
        local mappedX, mappedY = mapCoordinates(x, y)
        return face:verifyObject(mappedX, mappedY, z, object)
    end

    return proxy
end

return GarageBuildFaceProxy
