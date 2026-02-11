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
    density = 28,
    sampler_density = 65,
    play_mode_id = 2,
    play_speed = 20,
    one_shot = false,
    pitch_range = 28,
    sampler_pitch_range = 32,
    sampler_chord_scale = 30,
    focus_amount = 0,
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
    continuous = true,
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
