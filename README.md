# chordgrain

Chord aware granular sampler for norns with grid focus. Uses Glut as the audio engine.

## Install (norns)

1. Copy the chordgrain folder into your norns scripts folder.
2. Ensure the Glut engine is installed on norns (as script or engine).
3. Open chordgrain from the norns Scripts menu.

## Glut dependency and adapter

All engine calls go through the EngineAdapter module. If Glut is not available or calls fail, the app runs safely without audio. The adapter uses pcall for engine calls.

## Troubleshooting: "attempt to call a nil value (field 'cleanup')"

This can happen on the **first script load after boot** (when nothing has set `cleanup` yet) or when the previously running script did not define `cleanup`. Norns then tries to call it when clearing before loading chordgrain.

**Quick try:** Restart norns, open any built-in script first (e.g. from the default menu), then open chordgrain. That way `cleanup` is already set when you switch.

**Proper fix on norns:** Edit `/home/we/norns/lua/core/script.lua` as described in `docs/NORNS_CLEANUP_PATCH.md` so that `Script.clear` never calls a nil `cleanup` (set a safe default before calling the old one).
