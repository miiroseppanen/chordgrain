-- state.lua: chordgrain application state

local State = {}

function State.init()
  return {
    scale_id = 1,
    chord_id = 1,
    scale = nil,
    chord = nil,
    root = 0,
    octave = 3,
    grain_size = 30,
    density = 40,
    freeze = false,
    scrub = 0,
    continuous = false,
    playhead = 0,
    last_note = nil,
    last_pos = 0,
    sample_path = "",
    sample_name = "",
    last_tick_time = 0,
  }
end

return State
