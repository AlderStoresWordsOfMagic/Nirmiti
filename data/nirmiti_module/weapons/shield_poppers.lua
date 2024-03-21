-- [Shield Poppers - Manually pop shields with weapons. Contains code for both shield and hull collisions.] --

if not mods.nirmiti.implementedShieldPoppers then
mods.nirmiti.implementedShieldPoppers = true

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
    local popData = {
        type = node_get_value_default(node:first_attribute("type"), "pop"),
        count = node_get_number_default(node:first_attribute("count"), 0),
        countSuper = node_get_number_default(node:first_attribute("countSuper"), 0),
        crush = node_get_number_default(node:first_attribute("crush"), 0),
        sound = node_get_value_default(node:first_attribute("sound"), "")
    }
    return popData
end

-- [/// LOGIC /// ] ---

script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    if projectile.bDamageSuperShield == nil or projectile.bDamageSuperShield then
        local shieldPower = shipManager.shieldSystem.shields.power
        local popData = bp_tag_data(projectile.extend.name, "shieldPopper")
        if popData and (popData["type"] == "pop") then
            if shieldPower.super.first > 0 then
                if popData.countSuper > 0 then
                    shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
                    shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
                end
            else
                shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(), true)
                shieldPower.first = math.max(0, shieldPower.first - popData.count)
                if shieldPower.first == 0 then
                    shieldPower.first = shieldPower.first - popData.crush
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix(popData.sound, 1, true)
                end
            end
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local shieldSystem = shipManager.shieldSystem
    local popData = bp_tag_data(projectile.extend.name, "shieldPopper")
    if shieldSystem and popData and popData["type"] == "pierce" then
        shieldSystem:CollisionReal(location.x, location.y, Hyperspace.Damage(), true)
        shieldSystem.shields.power.first = math.max(0, shieldSystem.shields.power.first - popData.count) 
        if shieldSystem.shields.power.first == 0 then
            shieldSystem.shields.power.first = shieldSystem.shields.power.first - popData.crush
            Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix(popData.sound, 1, true)
        end
    end
    return Defines.Chain.CONTINUE
end)

-- [/// ADD TAG ///] --

bp_tag_add("weaponBlueprint", "shieldPopper", parser)

end