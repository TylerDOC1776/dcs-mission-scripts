# DCS Mission Scripts

A collection of Lua scripts for DCS World mission building. Drop them into your mission via a `MISSION START → DO SCRIPT FILE` trigger.

## Dependencies

Most scripts require **MOOSE** and/or **MIST** to be loaded before they run.

- [MOOSE](https://github.com/FlightControl-Master/MOOSE) — Mission Object Oriented Scripting Environment
- [MIST](https://github.com/mrSkortch/MissionScriptingTools) — Mission Scripting Tools

Load these first in your trigger chain, then load whichever scripts from this repo you need.

## Scripts

### flight_message.lua
Sends aircraft-family-aware flavor messages to players on spawn, takeoff, landing, and kill events. Supports fighters, attack aircraft, helicopters, bombers, transports, and warbirds. Kill messages distinguish air, ground, and sea targets.

### arty_strike.lua
Lets CAS and helicopter pilots call in scripted artillery via the F10 comms menu. Target with a laser designator or an F10 map mark. Configurable shell count, spread, delay, and cooldown at the top of the file.

### speed_kill.lua
Destroys a unit's group if its speed drops below a configurable threshold. Useful for cleaning up AI assets after landing or removing stalled aircraft. No external dependencies — uses only the DCS scripting API.

**Setup:**
1. Load at mission start: `MISSION START → DO SCRIPT FILE → speed_kill.lua`
2. On WP1 of any group, add a `Perform Command → Run Script` action:
   ```lua
   SpeedKill.watch("UnitName", minKnots)
   ```
   Optional third argument sets the check interval in seconds (default `2`):
   ```lua
   SpeedKill.watch("UnitName", 90, 5)
   ```
