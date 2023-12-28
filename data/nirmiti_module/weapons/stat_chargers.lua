-- [Stat Chargers - Charge the stats of a weapon instead of shot count.] --

if not mods.nirmiti.implementedStatChargers then
mods.nirmiti.implementedStatChargers = true

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
    local statBoosts = {}
    for childNode in node_children(node) do
        table.insert(statBoosts, childNode:name())
    end
    return statBoosts
end

-- [/// LOGIC ///] --

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local statBoosts = bp_tag_data(weapon.blueprint.name, "statCharger")
    if statBoosts then
        local shotsPerCharge = weapon.blueprint.miniProjectiles:size()
        if shotsPerCharge == 0 then 
            shotsPerCharge = 1
        end
        local queuedProjectiles = weapon.queuedProjectiles:size()
        local boost = queuedProjectiles // shotsPerCharge
        if queuedProjectiles % shotsPerCharge == 0 then
            weapon.queuedProjectiles:clear()
        end
        if projectile.death_animation.fScale ~= 0.25 then
            for _, stat in ipairs(statBoosts) do
                projectile.damage[stat] = boost + projectile.damage[stat]
            end
        end
    end
end)

-- [/// ADD TAG ///] --

bp_tag_add("weaponBlueprint", "statCharger", parser)

end
