local GarageProfiles = require "LMION/Services/Moveables/GarageProfiles"
local GarageMoveProps = {}

function GarageMoveProps.getSegment(moveProps, sprite)
    if moveProps and moveProps.lmionGarageSegment then return moveProps.lmionGarageSegment end
    return GarageProfiles.getSegmentBySprite(sprite or (moveProps and moveProps.sprite))
end

function GarageMoveProps.applyProfile(moveProps, sprite)
    if not moveProps then return nil end
    local segment = GarageProfiles.getSegmentBySprite(sprite or moveProps.sprite)
    local profile = segment and segment.profile
    if not profile then return nil end
    moveProps.isMoveable=true; moveProps.customItem=segment.itemType; moveProps.type="Object"
    moveProps.pickUpTool=profile.pickUpTool; moveProps.placeTool=profile.placeTool; moveProps.pickUpLevel=profile.pickUpLevel
    moveProps.rawWeight=profile.rawWeight; moveProps.weight=profile.weight; moveProps.canBreak=false; moveProps.facing=segment.facing
    moveProps.lmionGarageSegment=segment; moveProps.lmionGarageDefinitionId=profile.definitionId
    moveProps.lmionGaragePart=segment.roleIndex; moveProps.lmionGarageFacing=segment.facing; moveProps.lmionGarageIsOpen=segment.isOpen
    return segment
end

function GarageMoveProps.getFaces(moveProps)
    local s = GarageMoveProps.getSegment(moveProps); local p=s and s.profile; if not p then return nil end
    local role=s.role
    return { N=p.geometry.N[role].closed, W=p.geometry.W[role].closed }
end
return GarageMoveProps
