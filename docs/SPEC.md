# chordgrain SPEC

## Features

### Grid rows

Row 1: Scale select. X 1 to 16 chooses scale index.
Row 2: Chord select. X 1 to 16 chooses chord index.
Row 3: Root and octave: keys 1 to 12 set root semitone (0 to 11), keys 13 to 16 set octave (2 to 5).
Rows 4 to 8: Play area. Every key is one note and also one position trigger.

Grid formulas:
pos_norm = (x minus 1) / 15
degree = 1 + (y minus 4) times 16 + (x minus 1)

### Encoders

K1 short press: norns default menu toggle.
E1: Scrub, moves playhead.
K2: Grain size. Press toggles continuous mode.
K3: Density. Press toggles freeze.

### On screen

Main view shows grain size, density, speed, scale, chord, root, octave, note, sample position (percent), continuous (on/off), freeze (on/off), sample name, and top playhead and trigger markers.
Loading view shows control hints only during startup.

## Implementation goals

1. **Glut engine integration** All engine calls via adapter, safe behaviour without Glut.
2. **Sample loading** File param and SampleManager, adapter loads sample.
3. **Polyphonic chord play** Root plus chord intervals, chord_tones_limit and chord_spread, play_chord loop.
4. **Continuous mode** continuous and playhead, play_speed param, freeze locks position.

Default sample behavior:
- `sample_file` uses norns audio root `_path.audio` for file browsing
- On init, script checks `/home/we/dust/audio/common/hermit_leaves.wav`
- Then checks `/home/we/dust/audio/hermit_leaves.wav`
- If found, sets `sample_file` param and loads it through SampleManager
- If not found, script continues safely without sample load
- Manual sample load runs only when file path exists, invalid paths are ignored without script crash

## Grid transport compatibility

Grid transport is normalized in `lib/grid_backend.lua`. This keeps monome grid and midigrid behavior identical for key mapping, LED levels, and refresh timing.

Chord note visualization:
- Pressed play key is highlighted at full level in grid
- Other notes of selected chord are highlighted at medium level
- Scale, chord, root and octave changes retrigger the latest pressed note selection
- Playhead marker does not jump to note trigger position
