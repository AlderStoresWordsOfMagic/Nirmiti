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