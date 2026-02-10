# chordgrain grid mapping

Grid is 16x8 (128 keys).

## 16x8 schematic

Row 1: Scale select, x 1 to 16  
Row 2: Chord select, x 1 to 16  
Row 3: Root x 1 to 12, octave x 13 to 16  
Rows 4 to 8: Play area and position trigger

## Formulas

Position:
pos_norm = (x minus 1) / 15

Degree:
row_index = y minus 4  
degree = 1 + row_index times 8 + floor((x minus 1) / 2)

## LED policy

Selected controls: high  
Inactive controls: low  
Last trigger marker: medium  
Continuous playhead marker: low pulse

## Compatibility

The mapping and LED policy are device agnostic. `lib/grid_backend.lua` normalizes monome grid and midigrid transport so both follow the same key decode and LED output semantics.
