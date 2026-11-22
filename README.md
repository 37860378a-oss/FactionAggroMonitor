# Faction Aggro Monitor

**Version:** 0.1.0  
**Client:** World of Warcraft 3.3.5a (Interface 30300)  
**Author:** Charls

Visual proximity radar prototype for Trial of the Crusader (Faction Champions).

## Current prototype

- Movable radar window.
- Player-centered map-coordinate display.
- Attempts to display raid/party members and tracked units (target, mouseover, focus, boss1-boss5) when the 3.3.5 client provides map coordinates.
- Two configurable circular visual guide rings.
- Saved settings and slash commands.

## Important technical limitation

This addon does **not** read the server's actual NPC aggro radius or threat table. The rings are visual calibration guides only. WoW 3.3.5's GetPlayerMapPosition returns normalized map coordinates, not yards. The initial radius values are provisional map units and must be calibrated in the target server/instance.

NPC tracking is limited to unit tokens exposed by the client. The addon cannot enumerate every nearby creature or guarantee that Faction Champions appear as boss1-boss5.

## Install

Copy the FactionAggroMonitor folder into Interface/AddOns/ and reload the UI.

## Commands

- /fam — show/hide radar.
- /fam reset — reset radar position.
- /fam range 0.025 — set visual radius in normalized map units (not yards).
- /fam lock — toggle window movement lock.

## Calibration plan

1. Test in ToC 10-player and 25-player.
2. Verify which unit tokens expose champion coordinates.
3. Record the map-coordinate change at the moment champions begin moving.
4. Repeat from several positions and derive a reliable per-instance visual scale.

No claim of exact aggro range is made until server behavior has been measured.
