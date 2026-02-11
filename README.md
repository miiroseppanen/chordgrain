# chordgrain

Chord aware grid instrument for norns with two playback paths:
- Grain mode uses Glut for granular texture.
- Sampler mode uses Softcut transport for smoother full sample travel.

## Install (norns)

1. Copy the chordgrain folder into your norns scripts folder.
2. Ensure the Glut engine is installed on norns (as script or engine).
3. Open chordgrain from the norns Scripts menu.
4. In params, choose `Play mode`:
   - `Sampler` for smooth linear sample playback
   - `Grain` for granular Glut behavior

No extra setup is required. The script runs on a default norns.

## Controls

- K1 short press is norns default menu toggle
- E1 scrubs sample position
- E2 controls grain size
- K2 press toggles continuous mode
- E3 controls density
- K3 press toggles freeze

Grid play area behavior:
- Rows 4 to 8 use one note per key mapping
- Pressing one key triggers the selected chord from that note
- Grid highlights the pressed note and chord tones
- Scale, chord, root and octave changes retrigger the latest pressed note so changes are immediately audible
- Playhead does not jump on note press, it continues from transport position

Loading screen behavior:
- Control hints are shown only during startup loading screen
- Main view shows status and settings without hint text clutter

## Engine dependency and adapter

All engine calls go through the EngineAdapter module.
- Grain mode delegates to `lib/engine_glut.lua`.
- Sampler mode delegates to `lib/engine_softcut.lua`.

If an engine call fails, the adapter keeps the script running safely.

## Sample default

On init, chordgrain tries to load `hermit_leaves.wav` from norns audio library paths:
- `/home/we/dust/audio/common/hermit_leaves.wav`
- `/home/we/dust/audio/hermit_leaves.wav`

If found, this path is applied to `sample_file` and loaded automatically.

`sample_file` browser opens at `_path.audio` and manual selection stays available. Sample loads only run for paths that exist, so invalid paths are ignored safely.

## Grid parity checklist

- Connect monome grid and verify row mapping and LED levels
- Connect midigrid and run the same key sequence
- Confirm position and degree mapping match on both devices
- Confirm K1 short press always follows norns menu toggle behavior
