-- [Resource Weapons - Make weapons cost resources other than missiles to fire.] --

mods.nirmiti.resourceWeapons = {}
local resourceWeapons = mods.nirmiti.resourceWeapons

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local resourceCost = resourceWeapons[weapon.blueprint.name]
    if weapon.iShipId == 0 and resourceCost and is_first_shot(weapon, true) then
        if resourceCost.scrap then
            Hyperspace.ships.player:ModifyScrapCount(-resourceCost.scrap, false)
        end
        if resourceCost.fuel then
            Hyperspace.ships.player.fuel_count = Hyperspace.ships.player.fuel_count - resourceCost.fuel
        end
        if resourceCost.missiles then
            Hyperspace.ships.player:ModifyMissileCount(-resourceCost.missiles)
        end
        if resourceCost.drones then
            Hyperspace.ships.player:ModifyDroneCount(-resourceCost.drones)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local weapons = nil
    if pcall(function() weapons = Hyperspace.ships.player.weaponSystem.weapons end) and weapons then
        for weapon in vter(weapons) do
            local resourceCost = resourceWeapons[weapon.blueprint.name]
            if weapon.powered and resourceCost then
                if resourceCost.scrap and resourceCost.scrap > Hyperspace.ships.player.currentScrap then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.fuel and resourceCost.fuel > Hyperspace.ships.player.fuel_count then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.missiles and resourceCost.missiles > Hyperspace.ships.player:GetMissileCount() then
                    reset_weapon_charge(weapon)
                    return
                end
                if resourceCost.drones and resourceCost.drones > Hyperspace.ships.player:GetDroneCount() then
                    reset_weapon_charge(weapon)
                    return
                end
            end
        end
    end
end)
