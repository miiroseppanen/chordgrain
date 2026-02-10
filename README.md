# chordgrain

Chord aware granular sampler for norns with grid focus. Uses Glut as the audio engine.

## Install (norns)

1. Copy the chordgrain folder into your norns scripts folder.
2. Ensure the Glut engine is installed on norns (as script or engine).
3. Open chordgrain from the norns Scripts menu.

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
- Screen shows the same chord notes after key press

## Glut dependency and adapter

All engine calls go through the EngineAdapter module. If Glut is not available or calls fail, the app runs safely without audio. The adapter uses pcall for engine calls.

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
