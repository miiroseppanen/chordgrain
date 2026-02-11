# chordgrain SPEC

## Features

Playback modes:
- Grain mode: Glut granular playback.
- Sampler style mode: Glut playback with steadier continuous output and separate note pitch control.

### Grid rows

Row 1: Scale select. X 1 to 16 chooses scale index.
Row 2: Chord select. X 1 to 16 chooses chord index.
Rows 3 to 8: Keyboard rows. Each row is one octave and x 1 to 12 are notes.
Row 4, x 1 is Middle C.
Each row lower on grid is one octave lower.
x 13 to 16 are bright overflow keys reserved for future actions.

Grid formulas:
base_midi(y) = 60 + (4 minus y) times 12
midi = base_midi(y) + (x minus 1)

### Encoders

K1 short press: norns default menu toggle.
E1: Scrub, moves playhead.
K2: Grain size. Press toggles continuous mode.
K3: Density. Press toggles freeze.

### On screen

Main view shows mode, density, speed, scale, chord, root, octave, note, sample position (percent), continuous (on/off), freeze (on/off), sample name, and top playhead and trigger markers.
Loading view shows control hints only during startup.

## Implementation goals

1. **Engine integration** All engine calls route through adapter to Glut backend.
2. **Sample loading** File param and SampleManager, adapter loads sample.
3. **Polyphonic chord play** Root plus chord intervals, chord_tones_limit and chord_spread, play_chord loop.
4. **Continuous mode** continuous and playhead, play_speed param, freeze locks position.

Sampler mode behavior:
- Uses linear transport based playhead movement.
- Does not rely on periodic granular retrigger logic.
- Avoids frame by frame hard seek during continuous playback.
- Uses reduced pitch and chord scaling defaults to avoid mumble and excessive rate shifts.
- Pitch changes apply to note voice pitch and keep transport speed independent.

Default sample behavior:
- `sample_file` uses norns audio root `_path.audio` for file browsing
- On init, script checks `/home/we/dust/audio/hermit_leaves.wav`
- Then checks `/home/we/dust/audio/common/hermit_leaves.wav`
- If found, sets `sample_file` param and loads it through SampleManager
- If not found, script continues safely without sample load
- Manual sample load runs only when file path exists, invalid paths are ignored without script crash

## Grid transport compatibility

Grid transport is normalized in `lib/grid_backend.lua`. This keeps monome grid and midigrid behavior identical for key mapping, LED levels, and refresh timing.

Chord note visualization:
- Pressed play key is highlighted at full level in grid
- Other notes of selected chord are highlighted at medium level
- Scale and chord changes retrigger the latest pressed note selection
- Playhead marker does not jump to note trigger position
