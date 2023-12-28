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