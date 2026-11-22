# Faction Aggro Monitor

**Version:** 0.2.0  
**Client:** World of Warcraft 3.3.5a (Interface 30300)  
**Author:** Charls

Visual proximity radar prototype for Trial of the Crusader (Faction Champions).

## Version 0.2.0

- Adds a live target-range indicator using the configured spell, defaulting to the Spanish client spell name **Exorcismo**.
- Displays EN RANGO, FUERA DE RANGO, SIN DATO, or Sin objetivo in the radar status line.
- Adds `/fam spell Exorcismo` to change the spell used as a range reference.

The indicator uses the result of `IsSpellInRange`. It reports the spell's range only; it does **not** measure the Faction Champion's aggro radius.

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

- `/fam` — show/hide radar.
- `/fam reset` — reset radar position.
- `/fam range 0.025` — set visual guide radius in normalized map units (not yards).
- `/fam spell Exorcismo` — set the spell used for the target-range indicator.
- `/fam lock` — toggle window movement lock.

## Next calibration steps

1. Test the indicator with a Faction Champion selected at a distance where Exorcismo is out of range.
2. Approach until Exorcismo becomes available and confirm the status changes.
3. Separately observe when the champions begin moving; do not treat spell range as their aggro radius.
4. Repeat in ToC 10-player and 25-player to calibrate actual encounter behavior.

No claim of exact aggro range is made until server behavior has been measured.
