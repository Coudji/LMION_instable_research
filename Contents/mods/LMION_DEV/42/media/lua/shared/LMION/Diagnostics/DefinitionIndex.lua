local EntityIndex = require "LMION/Definitions/EntityIndex"
local DefinitionLookup = require "LMION/Services/DefinitionLookup"

local DefinitionIndexDiagnostics = {}

local PILOT_ENTITY = "Base.WhitePanelDoor"
local PILOT_DEFINITION = "Doors.Wood.WhitePanelDoor"

function DefinitionIndexDiagnostics.run()
    local entityIds = EntityIndex.getEntityIds()
    local definitionId = DefinitionLookup.getDefinitionIdByEntity(PILOT_ENTITY)

    if definitionId ~= PILOT_DEFINITION then
        error(
            "LMION: dev entity-index pilot mismatch for "
                .. PILOT_ENTITY
                .. ": expected "
                .. PILOT_DEFINITION
                .. ", got "
                .. tostring(definitionId),
            2
        )
    end

    print(string.format(
        "[LMION:DEV] entity index ready: %d mappings; %s -> %s",
        #entityIds,
        PILOT_ENTITY,
        definitionId
    ))
end

return DefinitionIndexDiagnostics
