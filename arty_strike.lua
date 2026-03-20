-- arty2.lua
-- CAS and helo players call scripted artillery via F10 menu.
-- Target: active laser designation (if equipped) or most recent F10 map mark.
-- PROXIMITY ENFORCED: player must be within max_range of the target.
-- Load via: MISSION START -> DO SCRIPT FILE -> arty2.lua
--
-- -----------------------------------------------------------------------
-- PLAYER INSTRUCTIONS
-- -----------------------------------------------------------------------
-- Only A-10, Su-25, AV-8B, and helicopter pilots have access to this.
--
-- You must be within range of your target — you cannot call from an airport.
--
-- To call a fire mission you need a target first. Two ways to mark one:
--
--   LASER: Point your laser designator at the target and hold it.
--          Then open the F10 menu and select "Request Arty Strike".
--          The strike fires at your laser spot.
--
--   F10 MARK: Open the F10 map, right-click your target, and place a mark.
--             You'll get a HUD confirmation. Then select "Request Arty Strike"
--             from the F10 comms menu. The mark is consumed on firing.
--             Place a new mark for the next mission.
--
-- After calling a strike you'll hear/see rounds impact within a few seconds.
-- There is a cooldown before you can call again — the menu will tell you
-- how long if you try too early.
-- -----------------------------------------------------------------------

local ArtyStrike = {}

-----------------------------------------------------------------------
-- Config
-----------------------------------------------------------------------
local CFG = {
    shells      = 8,      -- number of rounds per fire mission
    spread      = 60,     -- scatter radius in meters around target
    first_delay = 5,      -- seconds from call to first impact
    interval    = 1.2,    -- seconds between impacts
    power       = 300,    -- explosion yield per round (DCS units)
    cooldown    = 90,     -- seconds before same player can call again
    max_range   = 10,     -- max range in km from player to target
    menu_name   = "Request Arty Strike",
}

-----------------------------------------------------------------------
-- Aircraft families allowed to call
-----------------------------------------------------------------------
local CAN_CALL = { attack = true, helo = true }

local aircraftFamily = {
    -- Attack / CAS
    ["A-10C"]          = "attack",
    ["A-10C_2"]        = "attack",
    ["A-10A"]          = "attack",
    ["Su-25"]          = "attack",
    ["Su-25T"]         = "attack",
    ["AV8BNA"]         = "attack",
    -- Helicopters
    ["AH-64D_BLK_II"]  = "helo",
    ["Ka-50"]          = "helo",
    ["Ka-50_3"]        = "helo",
    ["Mi-8MT"]         = "helo",
    ["Mi-24P"]         = "helo",
    ["UH-1H"]          = "helo",
    ["SA342M"]         = "helo",
    ["SA342L"]         = "helo",
    ["OH58D"]          = "helo",
}

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------
local playerMarks = {}  -- [playerName] = Vec3, most recent F10 map mark
local cooldowns   = {}  -- [playerName] = timer.getTime() expiry
local groupMenus  = {}  -- [groupId] = true, prevents duplicate menu entries
local playerUnits = {}  -- [playerName] = unitName, updated on each spawn

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function getFamily(unit)
    return aircraftFamily[unit:getTypeName()] or "default"
end

local function findPlayerUnit(playerName)
    local unitName = playerUnits[playerName]
    if not unitName then return nil end
    return Unit.getByName(unitName)
end

local function msgToUnit(unit, text, duration)
    if unit and unit:isExist() then
        trigger.action.outTextForUnit(unit:getID(), text, duration or 12, false)
    end
end

local function dist2d(a, b)
    local dx = a.x - b.x
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dz * dz)
end

-----------------------------------------------------------------------
-- Strike execution
-----------------------------------------------------------------------
local function spawnRound(args, _)
    local r = CFG.spread
    local x = args.x + math.random(-r, r)
    local z = args.z + math.random(-r, r)
    local y = land.getHeight({x = x, y = z})
    trigger.action.explosion({x = x, y = y, z = z}, CFG.power)
end

local function fireMission(targetPos, callerUnit)
    local t = timer.getTime() + CFG.first_delay
    for i = 1, CFG.shells do
        timer.scheduleFunction(spawnRound, {x = targetPos.x, z = targetPos.z},
            t + (i - 1) * CFG.interval)
    end
    msgToUnit(callerUnit,
        string.format("Fire mission acknowledged. %d rounds, impact in %ds.", CFG.shells, CFG.first_delay),
        12)
end

-----------------------------------------------------------------------
-- F10 menu callback
-----------------------------------------------------------------------
local function requestStrike(args)
    local unit = findPlayerUnit(args.playerName)
    if not unit or not unit:isExist() then return end

    local name = unit:getPlayerName()
    local now  = timer.getTime()

    -- Cooldown check
    if cooldowns[name] and now < cooldowns[name] then
        local remaining = math.ceil(cooldowns[name] - now)
        msgToUnit(unit, string.format("Arty not ready. Available in %ds.", remaining), 10)
        return
    end

    -- Target resolution: laser first, then stored F10 mark
    local targetPos, source

    local ok, laserPt = pcall(function() return unit:getLaserPoint() end)
    if ok and laserPt then
        targetPos = laserPt
        source    = "laser"
    elseif playerMarks[name] then
        targetPos = playerMarks[name]
        source    = "F10 mark"
    end

    if not targetPos then
        msgToUnit(unit, "No target. Lase a target or place an F10 map mark first.", 12)
        return
    end

    -- Proximity check: player must be within max_range of the target
    local upos = unit:getPoint()
    local range_m = dist2d(upos, targetPos)
    if range_m > CFG.max_range * 1000 then
        msgToUnit(unit, string.format(
            "Too far from target. Must be within %d km (currently %.1f km).",
            CFG.max_range, range_m / 1000), 12)
        return
    end

    cooldowns[name]   = now + CFG.cooldown
    playerMarks[name] = nil  -- consume the stored mark

    msgToUnit(unit,
        string.format("Shot! (%s) Rounds on the way.", source), 10)
    fireMission(targetPos, unit)
end

-----------------------------------------------------------------------
-- Event handler
-----------------------------------------------------------------------
function ArtyStrike:onEvent(event)

    -- Add F10 menu when an eligible player spawns
    if event.id == world.event.S_EVENT_BIRTH then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            local family = getFamily(unit)
            if CAN_CALL[family] then
                local name = unit:getPlayerName()
                playerUnits[name] = unit:getName()
                local gid = unit:getGroup():getID()
                if not groupMenus[gid] then
                    missionCommands.addCommandForGroup(
                        gid, CFG.menu_name, nil, requestStrike, {playerName = name})
                    groupMenus[gid] = true
                end
            end
        end

    -- Store F10 map marks placed by eligible players
    elseif event.id == world.event.S_EVENT_MARK_ADDED
        or event.id == world.event.S_EVENT_MARK_CHANGE then
        local unit = event.initiator
        if unit and unit:getPlayerName() and event.pos then
            if CAN_CALL[getFamily(unit)] then
                local name = unit:getPlayerName()
                playerMarks[name] = event.pos
                msgToUnit(unit, "Target marked. Call '" .. CFG.menu_name .. "' from F10 menu.", 10)
            end
        end
    end

end

world.addEventHandler(ArtyStrike)

env.info("[ArtyStrike2] Script loaded successfully")
