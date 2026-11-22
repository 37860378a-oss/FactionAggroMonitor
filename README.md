# Faction Aggro Monitor

**Version:** 1.0.1  
**Client:** World of Warcraft 3.3.5a (Interface 30300)  
**Author:** Charls

## Generic detector foundation

This release replaces the previous encounter-specific prototype with a generic unit-observation core.

### What it detects
- Unit tokens exposed by the client: target, mouseover, focus, targettarget, boss1-boss5, arena1-arena5, party and raid.
- Name, GUID, friendly/hostile classification when the client API exposes it, and combat state when available.
- Names and GUIDs observed through COMBAT_LOG_EVENT_UNFILTERED, with a configurable memory timeout.

### Filters
- `/fam faction enemies`, `allies`, or `both`
- `/fam combat any`, `in`, or `out`
- `/fam name <text>` to filter by a partial unit name; `/fam name` clears it.
- `/fam list` lists currently exposed unit tokens.
- `/fam debug` prints tokens and recent combat-log observations.
- `/fam minimap` inspects tracking types plus direct Minimap child frames and regions; run it with tracking off and on to compare the UI tree.

### Minimap tracking investigation

Version 1.0.1 adds a read-only diagnostic command. `GetTrackingInfo()` reports which tracking mode is active, while `/fam minimap` lists the minimap frame children and regions (including texture names where available). This is an investigation aid only: it does not claim to read the engine-rendered humanoid blip coordinates. Compare output with tracking disabled and enabled.

## Important limitations
The combat log supplies names and GUIDs, not world coordinates, direction, or distance. A GUID observed in combat is not automatically a usable unit token. This version deliberately does not draw fake enemy positions.

The radar currently shows the player marker and detector counters. Directional NPC dots and yard-based proximity remain disabled until a valid 3.3.5a/Patagonia position source is demonstrated. Nameplates are not used.

The ring radius is a visual guide only, not yards or NPC aggro radius.

## Install
Copy the FactionAggroMonitor folder into `Interface/AddOns/` and use `/reload`.

## Commands
- `/fam` show/hide detector.
- `/fam debug` detailed diagnostics.
- `/fam list` list accessible units.
- `/fam faction enemies|allies|both`
- `/fam combat any|in|out`
- `/fam name <text>` partial name filter; omit text to clear.
- `/fam lock` toggle window lock.
- `/fam reset` reset window position.
- `/fam range <number>` adjust visual guide radius (normalized map value only).

## Test plan
1. Load the addon and run `/fam debug` while alone.
2. Target an enemy and run `/fam debug`; compare target token and combat log.
3. Enter Faction Champions and run `/fam debug` after combat starts.
4. Send the full chat output. We will use it to determine which encounter units the 3.3.5a client exposes.

No automatic nearby-creature enumeration or exact NPC distance is claimed.
