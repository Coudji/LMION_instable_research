local Resolver = require "LMION/Definitions/Resolver"
local Unlock = require "LMION/Services/Build/Unlock"

local VariantAvailability = {}

function VariantAvailability.isAvailable(member, player)
    if type(member) ~= "table" or type(member.definitionId) ~= "string" then
        return false
    end

    local definition = Resolver.resolveDefinition(member.definitionId)
    return Unlock.shouldShow(definition, player)
end

function VariantAvailability.getMembers(group, player)
    local result = {}
    local members = type(group) == "table" and group.members or nil

    if type(members) ~= "table" then
        return result
    end

    for index = 1, #members do
        local member = members[index]
        if VariantAvailability.isAvailable(member, player) then
            result[#result + 1] = member
        end
    end

    return result
end

function VariantAvailability.getRepresentative(group, player)
    local members = VariantAvailability.getMembers(group, player)
    return members[1]
end

return VariantAvailability
