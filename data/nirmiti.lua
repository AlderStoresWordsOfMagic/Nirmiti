-- Nirmiti: Sanskrit for "creation". --
-- Peer through the lines, and let it spark your creativity. --

-- Kudos to Chrono Vortex, plus Vertaalfout and Commander Julk for being the source of most of this Lua. --







-- [/// EVERYTHING BELOW THIS LINE IS NIRMITI CODE ///] --



-- [/// CORE LOGIC ///] --
-- [The heart and soul of Nirmiti.] --

-- [Namespace definition.] --

mods.nirmiti = {}

-- [Maximum value of a signed 32-bit integer field, used in some checks.]

local INT_MAX = 2147483647

-- [Hyperspace version check.] --

if not (Hyperspace.version and Hyperspace.version.major == 1 and Hyperspace.version.minor >= 8) then
    if not (Hyperspace.version.patch >= 0) then
        error("Incorrect Hyperspace version detected! Nirmiti requires Hyperspace 1.8+ to function.")
    end
end

-- [FUNCTION - Empty function, does nothing.]

function mods.nirmiti.pass()
end

-- [FUNCTION - Iterator function used to loop through tables, as HS Lua lacks one.] --

local vter = mods.nirmiti.vter

function mods.nirmiti.vter(cvec)
    local i = -1
    local n = cvec:size()
    return function()
        i = i + 1
        if i < n then return cvec[i] end
    end
end

-- [FUNCTION - It keeps things from exploding. It creates an empty table for some things, but... I dunno what things lack and need a table.]

local userdata_table = mods.nirmiti.userdata_table

function mods.nirmiti.userdata_table(userdata, tableName)
    if not userdata.table[tableName] then
        userdata.table[tableName] = {}
    end
    return userdata.table[tableName]
end

-- [FUNCTION - Copy a table recursively.]

function mods.nirmiti.table_copy_deep(value, cache, promises, copies)
    cache = cache or {}
    promises = promises or {}
    copies = copies or {}
    local copy
    if type(value) == 'table' then
        if (cache[value]) then
            copy = cache[value]
        else
            promises[value] = promises[value] or {}
            copy = {}
            for k, v in next, value, nil do
                local nKey = promises[k] or mods.vertexutil.table_copy_deep(k, cache, promises, copies)
                local nValue = promises[v] or mods.vertexutil.table_copy_deep(v, cache, promises, copies)
                copies[nKey] = type(k) == "table" and k or nil
                copies[nValue] = type(v) == "table" and v or nil
                copy[nKey] = nValue
            end
            local mt = getmetatable(value)
            if mt then
                setmetatable(copy, mt.__immutable and mt or mods.vertexutil.table_copy_deep(mt, cache, promises, copies))
            end
            cache[value] = copy
        end
    else
        copy = value
    end
    for k, v in pairs(copies) do
        if k == cache[v] then
            copies[k] = nil
        end
    end
    local function correctRec(tbl)
        if type(tbl) ~= "table" then return tbl end
        if copies[tbl] and cache[copies[tbl]] then
            return cache[copies[tbl]]
        end
        local new = {}
        for k, v in pairs(tbl) do
            local oldK = k
            k, v = correctRec(k), correctRec(v)
            if k ~= oldK then
                tbl[oldK] = nil
                new[k] = v
            else
                tbl[k] = v
            end
        end
        for k, v in pairs(new) do
            tbl[k] = v
        end
        return tbl
    end
    correctRec(copy)
    return copy
end



-- [/// WEAPON LOGIC ///] --
-- [Safeties off, everyone.] --

-- [Stat Chargers - Charge the stats of a weapon instead of shot count.]

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

-- [Cooldown Chargers - Reduce the cooldown of a weapon instead of shot count.]



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

        if painters[weaponName] then
            for drone in vter(Hyperspace.Global.GetInstance():GetShipManager((shipManager.iShipId + 1)%2).spaceDrones) do
                drone.targetLocation = location
            end
        end
    end
end)

-- [Drone Spawners - Set up weapons to summon external drones.]





-- [/// DRONE LOGIC ///] --
-- [Let loose the swarm.] --

-- [Missile Drones - Balancing methods for drones that fire missiles.] --

mods.nirmiti.missileDrones = {}
local missileDrones = mods.nirmiti.missileDrones

local deployedMissileDrones = {}

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    for drone in vter(ship.spaceDrones) do
        local missileDeployCost = missileDrones[drone.blueprint.name]
        if missileDeployCost then
            if drone.deployed then
                if not deployedMissileDrones[drone.selfId] then
                    deployedMissileDrones[drone.selfId] = true
                    if ship:GetMissileCount() >= missileDeployCost then
                        ship:ModifyMissileCount(-missileDeployCost)
                    else
                        drone:SetDestroyed(true, false)
                        ship:ModifyDroneCount(1)
                    end
                end
            else
                deployedMissileDrones[drone.selfId] = nil
            end
        end
    end
end)



-- [/// AUGMENT LOGIC ///] --
-- [Strength from within.] --

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



-- [/// CREW LOGIC ///] --
-- [Work smarter, not harder.] --

-- [Complex Behaviors - Gives crew AI unique behaviors when not controlled by the player. Actually written mostly by me!]

mods.nirmiti.complexCrew = {}
local complexCrew = mods.nirmiti.complexCrew

complexCrew["nirmiti_crew"] = {

  flee = true, -- Will try to flee from danger sources such as enemy crew.
  flee_hazards = false, -- Fires and breaches are included as threats.
  flee_exceptions = {}, -- Will not treat these crew types as threats.

  follow_targets = {} -- Will try to follow the closest instance of these crew types.

}

local function check_crew_enemies(crew1, crew2)
    if crew1.bMindControlled ~= crew2.bMindControlled then return crew1.iShipId == crew2.iShipId end
    return crew1.iShipId ~= crew2.iShipId
  end

local function check_crew_room_threat(crew, behaviorTable) -- check for threats (enemies, hazards) in the room
    for otherCrew in vter(Hyperspace.ships(crew.currentShipId).vCrewList) do
        local threat = crew.iRoomId == otherCrew.iRoomId and check_crew_enemies(crew, otherCrew) and not behaviorTable.flee_exceptions[otherCrew:GetSpecies()]
        if threat then return true end
    end
    return false
end

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
  if complexCrew[crew:GetSpecies()] then -- Test if crew has complex behavior
    if check_crew_room_threat(crew, complexCrew[crew:GetSpecies()]) then -- Flee behavior
      local ship = Hyperspace.ships(crew.currentShipId)
      local random_room = math.random(0, ship.ship.vRoomList:size() - 1)
      crew:MoveToRoom(random_room, 0, true)
    end
  end
end)



-- [/// GRAPHICAL LOGIC ///] --
-- [There is beauty in chaos.] --





-- [/// MISCELLANIOUS LOGIC ///] --
-- [Some things just can't be categorized.] --

-- [Enemy Intelligence - contains AI optimizations for enemy ships.]



-- [/// CUSTOM XML PARSERS ///] --
-- [The missing link.] --




