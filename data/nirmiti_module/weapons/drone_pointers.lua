-- [Drone Pointers - Retarget all drones to the targeted room.] --

if not mods.nirmiti.implementedDronePointers then
mods.nirmiti.implementedDronePointers = true

    -- [/// CORE IMPORTS ///] --

local parse_xml_bool = mods.nirmiti.parse_xml_bool
local node_children = mods.nirmiti.node_children
local node_get_value = mods.nirmiti.node_get_value
local node_get_value_default = mods.nirmiti.node_get_value_default
local node_get_number = mods.nirmiti.node_get_number
local node_get_number_default = mods.nirmiti.node_get_number_default
local node_get_bool_default = mods.nirmiti.node_get_bool_default
local bp_tag_data = mods.nirmiti.bp_tag_data
local bp_tag_add = mods.nirmiti.bp_tag_add

-- [/// PARSER ///] --

local function parser(node, bpName)
    local pointers = {}
    return pointers
end

-- [/// LOGIC /// ] ---

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local isPointer = bp_tag_data(projectile.extend.name, "dronePointer")
    if isPointer then
        for drone in vter(Hyperspace.Global.GetInstance():GetShipManager((shipManager.iShipId + 1)%2).spaceDrones) do
            drone.targetLocation = location
        end
    end
end)