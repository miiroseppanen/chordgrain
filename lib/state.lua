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
    grain_size = 70,
    density = 35,
    play_speed = 70,
    one_shot = true,
    pitch_range = 60,
    focus_amount = 60,
    focus_width = 12,
    focus_time_ms = 420,
    focus_active = false,
    focus_center = 0.5,
    focus_until = 0,
    focus_phase = 0,
    texture_jitter = 5,
    texture_spread = 5,
    freeze = false,
    scrub = 0,
    continuous = false,
    playhead = 0,
    last_note = nil,
    last_pos = 0,
    pressed_degree = nil,
    last_chord_notes = {},
    last_chord_degrees = {},
    sample_path = "",
    sample_name = "",
    last_tick_time = 0,
  }
end

return State
