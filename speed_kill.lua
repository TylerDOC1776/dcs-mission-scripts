-- speed_kill.lua
-- Destroys a unit's group if speed drops below a threshold.
--
-- Setup:
--   1. Add a MISSION START trigger: DO SCRIPT FILE -> speed_kill.lua
--   2. On any waypoint Run Script action, call:
--        SpeedKill.watch("UnitName", minKnots)
--      Optional third arg: check interval in seconds (default 2)
--        SpeedKill.watch("UnitName", minKnots, 5)

SpeedKill = {}

local KTS_TO_MPS = 0.514444

function SpeedKill.watch(unitName, minKnots, checkInterval)
    checkInterval = checkInterval or 2

    local function check(args, time)
        local unit = Unit.getByName(args.unitName)
        if not unit or not unit:isExist() then
            -- env.info("SpeedKill: unit not found or gone: " .. args.unitName)
            return nil
        end

        local vel   = unit:getVelocity()
        local speed = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)

        if speed < args.threshold then
            -- env.info("SpeedKill: destroying " .. args.unitName .. " at " .. string.format("%.1f", speed) .. " m/s")
            local group = unit:getGroup()
            if group then group:destroy() end
            return nil
        end

        return time + args.interval
    end

    -- env.info("SpeedKill: watching " .. unitName .. " threshold " .. minKnots .. " kts")
    timer.scheduleFunction(check, {
        unitName  = unitName,
        threshold = minKnots * KTS_TO_MPS,
        interval  = checkInterval,
    }, timer.getTime() + checkInterval)
end
