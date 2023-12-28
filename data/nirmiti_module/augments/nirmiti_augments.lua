-- [Regenerating Shield - An energy shield that regenerates some time after taking damage.]

mods.nirmiti.regenShields = {}
local regenShields = mods.nirmiti.regenShields

regenShields["NIRMITI_SHIELD"] = {
    max = 1,
    regen = 1,
    time = 10,
    color = Graphics.GL_Color(1.0, 0.47, 0.0, 1.0)
}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local shieldSys = nil
    if pcall(function() shieldSys = ship.shieldSystem end) and shieldSys then
        local partShieldData = nil
        local mostShields = 0
        for partShieldName, data in pairs(particleShields) do
            if ship:HasAugmentation(partShieldName) ~= 0 and data.max > mostShields then
                partShieldData = data
                mostShields = data.max
            end
        end
        if partShieldData and shieldSys.shields.power.super.first < partShieldData.max then
            local timer = userdata_table(ship, "mods.nirmiti.partShieldTimer")
            if not timer.time then
                timer.time = 0
            end
            timer.time = timer.time + Hyperspace.FPS.SpeedFactor/16
            if timer.time >= partShieldData.time then
                timer.time = 0
                for i = 1, math.min(partShieldData.max - shieldSys.shields.power.super.first, partShieldData.regen) do
                    shieldSys:AddSuperShield(shieldSys.center)
                    Hyperspace.Global.GetInstance():GetSoundControl():PlaySoundMix("nirmiti_regen_shield",0.3,true) -- [Sound can be changed.] --
                end
            end
            timer.progress = timer.time/partShieldData.time
            timer.color = partShieldData.color
        end
    end
end)

local outlineColor = Graphics.GL_Color(1.0, 1.0, 1.0, 1.0)

local function render_part_shield_charge(ship, width, x, y)
    local timer = userdata_table(ship, "mods.nirmiti.partShieldTimer")
    local progress = timer.progress
    if progress and progress > 0 and not ship.ship.bDestroyed then
        Graphics.CSurface.GL_DrawRectOutline(x, y, width, 6, outlineColor, 1)
        Graphics.CSurface.GL_DrawRect(2 + x, 2 + y, (width - 4)*progress, 2, timer.color)
    end
end

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, mods.nirmiti.pass, function()
    if Hyperspace.ships.player then render_part_shield_charge(Hyperspace.ships.player, 98, 30, 89) end
    if Hyperspace.ships.enemy then
        if Hyperspace.Global.GetInstance():GetCApp().gui.combatControl.boss_visual then
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 767, 113)
        else
            render_part_shield_charge(Hyperspace.ships.enemy, 60, 892, 157)
        end
    end
end)