-- [/// WEAPON LOGIC ///] --
-- [Safeties off, everyone.] --

-- [Stat Chargers - Charge the stats of a weapon instead of shot count.] --

mods.nirmiti.statChargers = {}
local statChargers = mods.nirmiti.statChargers

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local statBoosts = statChargers[weapon.blueprint.name]
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
            for _, statBoost in ipairs(statBoosts) do
                if statBoost.calc then
                    projectile.damage[statBoost.stat] = statBoost.calc(boost, projectile.damage[statBoost.stat])
                else
                    projectile.damage[statBoost.stat] = boost + projectile.damage[statBoost.stat]
                end
            end
        end
    end
end)

-- [Cooldown Chargers - Reduce the cooldown of a weapon instead of shot count.] --



-- [Area Weapons - Weapons that inflict damage to all adjacent rooms.] --



-- [Tile Beams - Beams that inflict their damage on every tile.] --



-- [Shield Poppers - Manually pop shields with weapons. Contains code for both shield and hull collisions.] --

mods.nirmiti.popShield = {}
local popShield = mods.nirmiti.popShield

script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    if projectile.bDamageSuperShield == nil or projectile.bDamageSuperShield then
        local shieldPower = shipManager.shieldSystem.shields.power
        local popData = nil
        if pcall(function() popData = popShield[Hyperspace.Get_Projectile_Extend(projectile).name] end) and popData then
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
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("nirmiti_shield_crush",1,true) -- [TODO: make sound changeable]
                end
            end
        end
    end
end)

mods.nirmiti.popHull = {}
local popHull = mods.nirmiti.popBallistics

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local shieldSystem = shipManager.shieldSystem
    local popData = nil
    if shieldSystem and pcall(function() popData = popHull[Hyperspace.Get_Projectile_Extend(projectile).name] end) and popData then
        shieldSystem:CollisionReal(location.x, location.y, Hyperspace.Damage(), true)
        shieldSystem.shields.power.first = math.max(0, shieldSystem.shields.power.first - popData.count) 
        if shieldSystem.shields.power.first == 0 then
            shieldSystem.shields.power.first = shieldSystem.shields.power.first - popData.crush
            Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("nirmiti_shield_crush",1,true) -- [TODO: make sound changeable]
        end
    end
    return Defines.Chain.CONTINUE
end)

-- [Social Engineering - Make weapons capable of inflicting a Mind Control effect.]



-- [Brute-Force Attack - Make weapons capable of inflicting a Hacking effect.]



-- [Resource Weapons - Make weapons cost resources other than missiles to fire.]

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

-- [Conservative Fix - Fixes the attack storage glitch with weapons that cost no power.] --



-- [Drone Pointers - Retarget all drones to the targeted room.] --

mods.nirmiti.pointers = {}
local pointers = mods.nirmiti.pointers

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(shipManager, projectile, location, damage, shipFriendlyFire)
    local weaponName = nil
    pcall(function() weaponName = Hyperspace.Get_Projectile_Extend(projectile).name end)
    if weaponName then

        if pointers[weaponName] then
            for drone in vter(Hyperspace.Global.GetInstance():GetShipManager((shipManager.iShipId + 1)%2).spaceDrones) do
                drone.targetLocation = location
            end
        end
    end
end)

-- [Drone Spawners - Set up weapons to summon external drones.]

