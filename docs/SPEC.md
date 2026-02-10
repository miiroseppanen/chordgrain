# chordgrain SPEC

## Features

### Grid rows

Row 1: Scale select. X 1 to 16 chooses scale index.
Row 2: Chord select. X 1 to 16 chooses chord index.
Row 3: Root and octave: keys 1 to 12 set root semitone (0 to 11), keys 13 to 16 set octave (2 to 5).
Rows 4 to 8: Play area. X sets position, Y sets degree.

### Encoders

K1: Scrub, moves playhead. Press toggles continuous mode.
K2: Grain size.
K3: Density. Press toggles freeze.

### On screen

Grain size, density, scale, chord, note, sample position (percent), continuous (on/off), freeze (on/off), playhead and last trigger bar.

## Implementation goals

1. **Glut engine integration** All engine calls via adapter, safe behaviour without Glut.
2. **Sample loading** File param and SampleManager, adapter loads sample.
3. **Polyphonic chord play** Root plus chord intervals, chord_tones_limit and chord_spread, play_chord loop.
4. **Continuous mode** continuous and playhead, play_speed param, freeze locks position.
