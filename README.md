# chordgrain

Chord aware granular sampler for norns with grid focus. Uses Glut as the audio engine.

## Install (norns)

1. Copy the chordgrain folder into your norns scripts folder.
2. Ensure the Glut engine is installed on norns (as script or engine).
3. Open chordgrain from the norns Scripts menu.

## Glut dependency and adapter

All engine calls go through the EngineAdapter module. If Glut is not available or calls fail, the app runs safely without audio. The adapter uses pcall for engine calls.
