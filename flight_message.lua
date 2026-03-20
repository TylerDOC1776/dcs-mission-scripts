-- Flight Message for DCS World
-- Place this in your mission via a "DO SCRIPT" or "DO SCRIPT FILE" trigger
-- Trigger: MISSION START -> DO SCRIPT FILE -> good_flight.lua

local FlightMessage = {}

-----------------------------------------------------------------------
-- Utility
-----------------------------------------------------------------------
local function pick(tbl)
    return tbl[math.random(#tbl)]
end

local function msgToUnit(unit, text, duration)
    if unit and unit:isExist() then
        trigger.action.outTextForUnit(unit:getID(), text, duration or 15, false)
    end
end

-----------------------------------------------------------------------
-- Aircraft-specific messages
-----------------------------------------------------------------------
-- Categories map DCS type names to a family for message selection.
-- Add more entries as needed.
local aircraftFamily = {
    -- Fighters
    ["F-16C_50"]       = "fighter",
    ["F-16C bl.50"]    = "fighter",
    ["FA-18C_hornet"]  = "fighter",
    ["F-15C"]          = "fighter",
    ["F-15E"]          = "fighter",
    ["F-15ESE"]        = "fighter",
    ["F-14A-135-GR"]   = "fighter",
    ["F-14B"]          = "fighter",
    ["F-4E-45MC"]      = "fighter",
    ["Su-27"]          = "fighter",
    ["Su-33"]          = "fighter",
    ["MiG-29A"]        = "fighter",
    ["MiG-29S"]        = "fighter",
    ["JF-17"]          = "fighter",
    ["M-2000C"]        = "fighter",
    ["Mirage-F1CE"]    = "fighter",
    ["Mirage-F1EE"]    = "fighter",

    -- Attack / CAS
    ["A-10C"]          = "attack",
    ["A-10C_2"]        = "attack",
    ["A-10A"]          = "attack",
    ["Su-25"]          = "attack",
    ["Su-25T"]         = "attack",
    ["AV8BNA"]         = "attack",

    -- Helicopters
    ["AH-64D_BLK_II"]  = "helo",
    ["Ka-50"]           = "helo",
    ["Ka-50_3"]         = "helo",
    ["Mi-8MT"]          = "helo",
    ["Mi-24P"]          = "helo",
    ["UH-1H"]           = "helo",
    ["SA342M"]          = "helo",
    ["SA342L"]          = "helo",
    ["OH58D"]           = "helo",

    -- Bombers / Strike
    ["B-1B"]           = "bomber",
    ["Tu-95MS"]        = "bomber",
    ["Tu-160"]         = "bomber",

    -- Transport / Tanker
    ["C-130"]          = "transport",
    ["C-17A"]          = "transport",
    ["KC135MPRS"]      = "transport",

    -- Warbirds
    ["SpitfireLFMkIX"]  = "warbird",
    ["P-51D"]           = "warbird",
    ["P-51D-30-NA"]     = "warbird",
    ["FW-190D9"]        = "warbird",
    ["Bf-109K-4"]       = "warbird",
    ["P-47D-30"]        = "warbird",
    ["P-47D-40"]        = "warbird",
    ["MosquitoFBMkVI"]  = "warbird",
    ["I-16"]            = "warbird",
}

-----------------------------------------------------------------------
-- Spawn/Birth messages by aircraft family
-----------------------------------------------------------------------
local spawnMessages = {
    fighter = {
        "%s, welcome to the %s. Systems are green, you're cleared to start!",
        "%s, strapping into the %s. Let's make this one count!",
        "%s, %s cockpit checks complete. Ready when you are!",
        "%s, you're in the %s. Time to hunt!",
        "%s, manning the %s. Show them what you've got!",
    },
    attack = {
        "%s, %s is yours. Lock and load!",
        "%s, settling into the %s. Ground pounders stand by!",
        "%s, %s systems nominal. Ordnance is ready!",
        "%s, %s cockpit hot. Let's bring the thunder!",
        "%s, you're in the %s. Time to make some noise!",
    },
    helo = {
        "%s, %s is spooling up. Rotors ready!",
        "%s, strapping into the %s. Stay low, stay alive!",
        "%s, %s crew ready. Let's dance with the trees!",
        "%s, manning the %s. Nap of the earth, pilot!",
        "%s, %s is yours. Time to go hunting!",
    },
    bomber = {
        "%s, %s crew ready. Payload standing by!",
        "%s, settling into the %s. Time to deliver the mail!",
        "%s, %s cockpit checks complete. Bombs are waiting!",
        "%s, you're in the heavy. Let's make it count!",
    },
    transport = {
        "%s, %s is ready for duty. Cargo is secure!",
        "%s, strapping into the %s. Let's deliver the goods!",
        "%s, %s crew aboard. Passengers are counting on you!",
        "%s, manning the %s. Safe skies ahead!",
    },
    warbird = {
        "%s, the %s awaits! Chocks away when ready!",
        "%s, settling into the %s. History in the making!",
        "%s, %s crew ready. Let's show them how it's done!",
        "%s, you're in the %s. Fly with honor, pilot!",
        "%s, manning the %s. Tally-ho!",
    },
    default = {
        "%s, welcome to the %s. Systems are green!",
        "%s, strapping into the %s. Good luck out there!",
        "%s, %s is ready. Fly safe!",
        "%s, you're in the %s. Have a good flight!",
        "%s, manning the %s. Cleared to proceed!",
    },
}

-----------------------------------------------------------------------
-- Takeoff messages by aircraft family
-----------------------------------------------------------------------
local takeoffMessages = {
    fighter = {
        "%s, wheels up in the %s. Go get 'em!",
        "%s, %s airborne. Fox hunt is on!",
        "%s, you're off the deck in the %s. Own the sky!",
        "%s, %s is clean and climbing. Happy hunting!",
        "%s, gear up in the %s. Show 'em what you've got!",
    },
    attack = {
        "%s, %s rolling out. Time to bring the pain!",
        "%s, airborne in the %s. Go make some craters!",
        "%s, %s is up. Give 'em hell down there!",
        "%s, mud hen is off the ground. Happy tank plinking!",
        "%s, %s climbing out. The ground targets won't know what hit 'em!",
    },
    helo = {
        "%s, %s is off the pad. Stay low, stay deadly!",
        "%s, rotors are biting in the %s. Fly safe out there!",
        "%s, %s lifting off. Nap of the earth, pilot!",
        "%s, skids up in the %s. Watch the tree lines!",
        "%s, %s is airborne. Keep those rotors spinning!",
    },
    bomber = {
        "%s, %s is wheels up. Payload on the way!",
        "%s, the %s is airborne. Time to rearrange some geography!",
        "%s, heavy is off the ground. Bomb bay is waiting!",
        "%s, %s climbing to angels. Delivery inbound!",
    },
    transport = {
        "%s, %s rolling. Smooth skies ahead, captain!",
        "%s, heavy lifter %s is airborne. Deliver the goods!",
        "%s, %s is up. Fly safe, cargo is counting on you!",
    },
    warbird = {
        "%s, the %s roars to life! Tally-ho!",
        "%s, off the grass in the %s. Give 'em a proper scrap!",
        "%s, %s airborne. Chocks away and good hunting!",
        "%s, your %s climbs into history. Fly with honor!",
        "%s, throttle forward in the %s. Bandits beware!",
    },
    default = {
        "%s, airborne in the %s. Good flight!",
        "%s, %s is up. Blue skies ahead!",
        "%s, wheels up in the %s. Enjoy the ride!",
        "%s, %s climbing out. Have a great sortie!",
    },
}

-----------------------------------------------------------------------
-- Landing messages by aircraft family
-----------------------------------------------------------------------
local landingMessages = {
    fighter = {
        "%s, nice trap! The %s is back safe.",
        "%s, %s on deck. Debrief in the ready room!",
        "%s, welcome back in the %s. Another mission in the books!",
        "%s, %s is down. The bar is open, pilot!",
    },
    attack = {
        "%s, %s back on the ground. How's the ammo count?",
        "%s, hog driver is home! Nice work in the %s.",
        "%s, %s down safe. Rearm and refuel!",
        "%s, good recovery in the %s. Ground crews standing by!",
    },
    helo = {
        "%s, %s is on the pad. Smooth landing!",
        "%s, skids down in the %s. Welcome home!",
        "%s, rotors winding down. Nice flying in the %s!",
        "%s, %s has landed. Crew chief gives you a thumbs up!",
    },
    bomber = {
        "%s, %s is on the ground. Payload delivered!",
        "%s, heavy has landed. Good work in the %s!",
        "%s, %s down safe. Mission accomplished!",
    },
    transport = {
        "%s, %s has landed. Cargo delivered!",
        "%s, smooth touchdown in the %s. Passengers are grateful!",
        "%s, %s on the ramp. Another delivery complete!",
    },
    warbird = {
        "%s, the %s touches down. A proper landing, old chap!",
        "%s, %s back on the field. Well fought!",
        "%s, three-pointer in the %s. The squadron cheers!",
        "%s, %s rolls to a stop. Tea is served in the mess!",
    },
    default = {
        "%s, welcome back! %s is on the ground.",
        "%s, %s has landed. Nice flying out there!",
        "%s, touchdown in the %s. Good to have you back!",
        "%s, %s down safe. Well done, pilot!",
    },
}

-----------------------------------------------------------------------
-- Kill messages by target category
-----------------------------------------------------------------------
local killMessages = {
    air = {
        "%s splashed a bogey! That's a kill on %s!",
        "%s, confirmed air-to-air kill! %s is going down!",
        "%s got one! %s is a fireball!",
        "%s, you just made %s a lawn dart. Splash one!",
        "%s, SPLASH! %s is off the scope!",
        "%s, Fox kill! %s won't be coming home!",
        "%s, that %s just became a parts catalog. Nice shot!",
    },
    ground = {
        "%s, direct hit! %s is toast!",
        "%s, scratch one %s. Good effect on target!",
        "%s, %s destroyed! That's how it's done!",
        "%s, SHACK! %s is burning!",
        "%s, %s eliminated! Moving to next target!",
        "%s, good hit on the %s. Secondaries observed!",
    },
    sea = {
        "%s, %s is taking on water. Good hit!",
        "%s, confirmed kill on %s! She's going down!",
        "%s, %s is sinking! One less ship to worry about!",
        "%s, that %s just became a submarine. Nice shot!",
    },
    default = {
        "%s, target %s destroyed!",
        "%s, confirmed kill on %s! Nice work!",
        "%s, %s is history. Moving on!",
        "%s scored a kill on %s!",
    },
}

-----------------------------------------------------------------------
-- Helper: determine target category for kill messages
-----------------------------------------------------------------------
local function getTargetCategory(target)
    if not target then return "default" end

    -- hasAttribute is reliable across all object types and DCS versions
    local ok, isAir = pcall(target.hasAttribute, target, "Air")
    if ok and isAir then return "air" end

    local ok2, isSea = pcall(target.hasAttribute, target, "Ships")
    if ok2 and isSea then return "sea" end

    return "ground"
end

-----------------------------------------------------------------------
-- Helper: get aircraft family or default
-----------------------------------------------------------------------
local function getFamily(unit)
    local typeName = unit:getTypeName()
    return aircraftFamily[typeName] or "default"
end

-----------------------------------------------------------------------
-- Event handler
-----------------------------------------------------------------------
function FlightMessage:onEvent(event)

    -- BIRTH/SPAWN (when player enters aircraft)
    if event.id == world.event.S_EVENT_BIRTH then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            local name = unit:getPlayerName()
            local aircraft = unit:getTypeName()
            local family = getFamily(unit)
            local msgs = spawnMessages[family] or spawnMessages.default
            local msg = string.format(pick(msgs), name, aircraft)
            msgToUnit(unit, msg, 15)
        end

    -- TAKEOFF
    elseif event.id == world.event.S_EVENT_TAKEOFF then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            local name = unit:getPlayerName()
            local aircraft = unit:getTypeName()
            local family = getFamily(unit)
            local msgs = takeoffMessages[family] or takeoffMessages.default
            local msg = string.format(pick(msgs), name, aircraft)
            msgToUnit(unit, msg, 15)
        end

    -- LANDING
    elseif event.id == world.event.S_EVENT_LAND then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            local name = unit:getPlayerName()
            local aircraft = unit:getTypeName()
            local family = getFamily(unit)
            local msgs = landingMessages[family] or landingMessages.default
            local msg = string.format(pick(msgs), name, aircraft)
            msgToUnit(unit, msg, 15)
        end

    -- KILL
    elseif event.id == world.event.S_EVENT_KILL then
        local killer = event.initiator
        local target = event.target
        if killer and killer.getPlayerName and killer:getPlayerName() then
            local name = killer:getPlayerName()
            local targetName = "unknown"
            if target then
                targetName = target:getTypeName() or "unknown"
            end
            local category = getTargetCategory(target)
            local msgs = killMessages[category] or killMessages.default
            local msg = string.format(pick(msgs), name, targetName)
            msgToUnit(killer, msg, 15)
        end
    end
end

world.addEventHandler(FlightMessage)

env.info("[FlightMessage] Script loaded successfully")