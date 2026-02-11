# chordgrain grid mapping

Grid is 16x8 (128 keys).

## 16x8 schematic

Row 1: Scale select, x 1 to 16  
Row 2: Chord select, x 1 to 16  
Rows 3 to 8: Keyboard rows where each row is one octave

Anchor:
Row 4, x 1 is Middle C.

Octave direction:
From top to bottom, each next row is one octave lower.

Overflow keys:
x 13 to 16 are marked bright and reserved for future functions.

## Formulas

Note:
base_midi(y) = 60 + (4 minus y) times 12  
midi = base_midi(y) + (x minus 1), for x 1 to 12 and y 3 to 8

## LED policy

Selected controls: high  
Inactive controls: low  
Last trigger marker: medium  
Continuous playhead marker: low pulse  
Pressed note: full  
Chord tones for pressed note: medium
Overflow keys: bright

## Compatibility

The mapping and LED policy are device agnostic. `lib/grid_backend.lua` normalizes monome grid and midigrid transport so both follow the same key decode and LED output semantics.
