-- [Resource Weapons - Make weapons cost resources other than missiles to fire.] --

if not mods.nirmiti.implementedResourceWeapons then
mods.nirmiti.implementedResourceWeapons = true

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

local vter = mods.nirmiti.vter -- add to all scripts requiring vter
local is_first_shot = mods.multiverse.is_first_shot -- add to all scripts requiring is_first_shot

-- [/// PARSER ///] --

local function parser(node, bpName)
    local resourceCost = {
        type = node_get_value_default(node:first_attribute("type"), "scrap"),
        count = node_get_number_default(node:first_attribute("count"), 0)
    }
    return resourceCost
end

-- [/// LOGIC ///] ---

local function reset_weapon_charge(weapon)
    weapon.cooldown.first = 0
    weapon.chargeLevel = 0
end

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon) -- Consume resource when fired
    local resourceCost = bp_tag_data(projectile.extend.name, "resourceCost")
    if weapon.iShipId == 0 and resourceCost and is_first_shot(weapon, true) then
        if resourceCost.type == "scrap" then
            Hyperspace.ships.player:ModifyScrapCount(-resourceCost.count, false)
        end
        if resourceCost.type == "fuel" then
            Hyperspace.ships.player.fuel_count = Hyperspace.ships.player.fuel_count - resourceCost.count
        end
        if resourceCost.type == "missiles" then
            Hyperspace.ships.player:ModifyMissileCount(-resourceCost.count)
        end
        if resourceCost.type == "drones" then
            Hyperspace.ships.player:ModifyDroneCount(-resourceCost.count)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function() -- Prevent weapon from charging when lacking resource
    local weapons = nil
    if pcall(function() weapons = Hyperspace.ships.player.weaponSystem.weapons end) and weapons then
        for weapon in vter(weapons) do
            local resourceCost = bp_tag_data(weapon.blueprint.name, "resourceCost")
            if weapon.powered and resourceCost then
                if resourceCost.type == "scrap" and resourceCost.count > Hyperspace.ships.player.currentScrap then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.type == "fuel" and resourceCost.count > Hyperspace.ships.player.fuel_count then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.type == "missiles" and resourceCost.count > Hyperspace.ships.player:GetMissileCount() then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.type == "drones" and resourceCost.count > Hyperspace.ships.player:GetDroneCount() then
                    reset_weapon_charge(weapon)
                    return
                end
            end
        end
    end
end)

-- [/// ADD TAG ///] --

bp_tag_add("weaponBlueprint", "resourceCost", parser)