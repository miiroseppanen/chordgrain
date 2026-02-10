-- chordgrain
-- granular chord sampler
-- norns: E1 pos E2 grain E3 den
-- norns: K1 menu K2 cont K3 freeze
-- grid: r1 scale r2 chord
-- grid: r3 root/oct r4-8 play

engine.name = "Glut"

local State = include("lib/state")
local Scales = include("lib/scales")
local Chords = include("lib/chords")
local GridMap = include("lib/gridmap")
local GridBackend = include("lib/grid_backend")
local UI = include("lib/ui")
local EngineAdapter = include("lib/engine_adapter")
local SampleManager = include("lib/sample_manager")

local s
local tick_metro

local DEFAULT_SAMPLE_PATHS = {
  "/home/we/dust/audio/common/hermit_leaves.wav",
  "/home/we/dust/audio/hermit_leaves.wav",
}

local PLAY_CENTER_X = 8
local PLAY_ROW_OCTAVE_SHIFT = {
  [4] = 0,
  [5] = 1,
  [6] = -1,
  [7] = 2,
  [8] = -2,
}

local function valid_sample_path(path)
  if not path or path == "" then
    return false
  end
  if not util or not util.file_exists then
    return false
  end
  return util.file_exists(path)
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function has_sample_loaded()
  local from_params = params and params:get("sample_file") or nil
  if valid_sample_path(from_params) then
    return true
  end
  return valid_sample_path(s and s.sample_path or nil)
end

local function open_sample_menu()
  if norns and norns.menu and norns.menu.toggle then
    norns.menu.toggle(true)
  end
end

local function sync_state_from_params()
  s.grain_size = params:get("grain_size")
  s.density = params:get("density")
  s.play_speed = params:get("play_speed")
  s.one_shot = params:get("one_shot") == 2
  s.pitch_range = params:get("pitch_range")
  s.focus_amount = params:get("focus_amount")
  s.focus_width = params:get("focus_width")
  s.focus_time_ms = params:get("focus_time_ms")
  s.texture_jitter = params:get("texture_jitter")
  s.texture_spread = params:get("texture_spread")
  s.freeze = params:get("freeze") == 2
  s.quantize = params:get("quantize") == 2
  s.chord_spread = params:get("chord_spread") / 100
  s.chord_tones_limit = (params:get("chord_tones_limit") or 2) + 1
  s.scale = Scales.get_scale(s.scale_id)
  s.chord = Chords.get_chord(s.chord_id)
end

local function wrap_play_degree(v)
  return ((v - 1) % 80) + 1
end

local function scale_steps_to_midi(step_offset, root_semitone, octave_base, scale_intervals, quantize)
  local tonic = (octave_base + 1) * 12 + root_semitone
  if quantize == false then
    return tonic + step_offset
  end

  if not scale_intervals or #scale_intervals == 0 then
    scale_intervals = { 0, 2, 4, 5, 7, 9, 11 }
  end

  local n = #scale_intervals
  if step_offset >= 0 then
    local oct = math.floor(step_offset / n)
    local idx = step_offset % n
    return tonic + scale_intervals[idx + 1] + oct * 12
  end

  local abs_steps = -step_offset
  local oct = math.floor(abs_steps / n)
  local idx = abs_steps % n
  if idx == 0 then
    return tonic - (oct * 12)
  end
  return tonic + scale_intervals[n - idx + 1] - ((oct + 1) * 12)
end

local function play_degree_to_midi(play_degree)
  local x, y = GridMap.degree_to_key(play_degree)
  x = x or PLAY_CENTER_X
  y = y or 4
  local intervals = s.scale and s.scale.intervals
  local octave_shift = PLAY_ROW_OCTAVE_SHIFT[y] or 0
  local steps_per_oct = intervals and #intervals or 7
  local step_offset = (x - PLAY_CENTER_X) + (octave_shift * steps_per_oct)
  return scale_steps_to_midi(step_offset, s.root, s.octave, intervals, s.quantize)
end

local function focus_center_from_pos(pos_norm)
  local amount = clamp((s.focus_amount or 0) / 100, 0, 1)
  return clamp((pos_norm * (1 - amount)) + (0.5 * amount), 0, 1)
end

local function trigger_at(pos_norm, degree)
  sync_state_from_params()
  pos_norm = clamp(pos_norm or 0, 0, 1)
  local midi = play_degree_to_midi(degree)
  local chord = s.chord
  local intervals = chord and chord.intervals or { 0 }
  local limit = s.chord_tones_limit or 3
  local notes = Chords.chord_notes(midi, intervals, limit)
  local chord_degrees = {}
  if intervals and #intervals > 0 then
    for i = 1, math.min(limit, #intervals) do
      local d = degree + (intervals[i] or 0)
      chord_degrees[#chord_degrees + 1] = wrap_play_degree(d)
    end
  else
    chord_degrees[1] = degree
  end
  local opts = {
    chord_spread = s.chord_spread or 0.02,
    chord_tones_limit = limit,
    one_shot = s.one_shot,
    one_shot_release_s = 0.20,
    pitch_range = s.pitch_range or 40,
  }
  local focused_pos = focus_center_from_pos(pos_norm)
  EngineAdapter.play_chord(notes, focused_pos, opts)
  s.focus_center = focused_pos
  s.focus_phase = 0
  s.focus_until = util.time() + ((s.focus_time_ms or 0) / 1000)
  s.focus_active = (s.focus_amount or 0) > 0 and (s.focus_time_ms or 0) > 0
  s.last_note = midi
  s.last_pos = focused_pos
  s.pressed_degree = degree
  s.last_chord_notes = notes
  s.last_chord_degrees = chord_degrees
  EngineAdapter.set_position(focused_pos)
end

local function retrigger_current_selection()
  if not s or not s.pressed_degree then
    return
  end
  local pos = s.last_pos
  if pos == nil then
    pos = s.playhead or s.scrub or 0
  end
  trigger_at(pos, s.pressed_degree)
end

local function grid_key(g, x, y, z)
  if z == 0 then return end
  local scale_id = GridMap.key_to_scale_id(x, y)
  if scale_id then
    s.scale_id = scale_id
    s.scale = Scales.get_scale(scale_id)
    retrigger_current_selection()
    return
  end
  local chord_id = GridMap.key_to_chord_id(x, y)
  if chord_id then
    s.chord_id = chord_id
    s.chord = Chords.get_chord(chord_id)
    retrigger_current_selection()
    return
  end
  local root, oct = GridMap.key_to_root(x, y)
  if root ~= nil then
    s.root = root
    retrigger_current_selection()
    return
  end
  if oct ~= nil then
    s.octave = oct
    retrigger_current_selection()
    return
  end
  local pos_norm, degree = GridMap.key_to_play(x, y)
  if pos_norm and degree then
    trigger_at(pos_norm, degree)
  end
end

local function handle_enc(n, d)
  if n == 1 then
    s.scrub = math.max(0, math.min(1, s.scrub + d * 0.02))
    s.playhead = s.scrub
    EngineAdapter.set_position(s.scrub)
  elseif n == 2 then
    params:delta("grain_size", d)
    s.grain_size = params:get("grain_size")
    EngineAdapter.set_grain_size(s.grain_size)
  elseif n == 3 then
    params:delta("density", d)
    s.density = params:get("density")
    EngineAdapter.set_density(s.density)
  end
end

local function handle_key(n, z)
  if z == 0 then return end
  if n == 1 then return end
  if (n == 2 or n == 3) and not has_sample_loaded() then
    open_sample_menu()
    return
  end
  if n == 2 then
    s.continuous = not s.continuous
    if s.continuous then
      s.playhead = s.last_pos and s.last_pos or s.scrub
      EngineAdapter.set_position(s.playhead)
    end
  elseif n == 3 then
    params:set("freeze", 1 - params:get("freeze"))
    s.freeze = params:get("freeze") == 2
    EngineAdapter.set_freeze(s.freeze)
  end
end

local function tick()
  if not s then return end
  local t = util.time()
  local dt = s.last_tick_time > 0 and (t - s.last_tick_time) or 0.033
  s.last_tick_time = t

  sync_state_from_params()

  if s.continuous and not s.freeze and not s.one_shot then
    local speed_pct = params:get("play_speed") or 100
    local advance = (speed_pct / 60 / 60) * dt
    s.playhead = s.playhead + advance
    if s.playhead >= 1 then s.playhead = s.playhead - 1 end
    if s.playhead < 0 then s.playhead = s.playhead + 1 end
    EngineAdapter.set_position(s.playhead)
  end

  if s.focus_active and not s.freeze then
    if t < (s.focus_until or 0) then
      local width = clamp((s.focus_width or 0) / 100, 0.01, 0.5)
      s.focus_phase = (s.focus_phase or 0) + (dt * 2.2)
      local wobble = math.sin((s.focus_phase or 0) * math.pi * 2) * (width * 0.35)
      local focused_pos = clamp((s.focus_center or 0.5) + wobble, 0, 1)
      s.playhead = focused_pos
      EngineAdapter.set_position(focused_pos)
    else
      s.focus_active = false
    end
  end

  EngineAdapter.tick(dt, s)
  GridBackend.render(GridMap.render_leds, s)
  if not (norns and norns.menu and norns.menu.status and norns.menu.status()) then
    UI.redraw(s)
  end
end

local function init_params()
  if not params then return end
  params:add_separator("chordgrain_sample", "Sample")
  if params.add and _path and _path.audio then
    params:add({
      type = "file",
      id = "sample_file",
      name = "Sample",
      path = _path.audio,
    })
  else
    params:add_file("sample_file", "Sample")
  end

  params:add_separator("chordgrain_defaults", "Default settings")
  params:add_number("grain_size", "Grain size", 1, 100, 70)
  params:add_number("density", "Density", 1, 100, 35)
  params:add_number("play_speed", "Play speed", 1, 200, 70)
  params:add_option("one_shot", "One shot mode", { "Off", "On" }, 2)
  params:add_number("pitch_range", "Pitch range", 0, 100, 60)
  params:add_number("focus_amount", "Focus amount", 0, 100, 60)
  params:add_number("focus_width", "Focus width", 1, 50, 12)
  params:add_number("focus_time_ms", "Focus time ms", 0, 2000, 420)
  params:add_number("texture_jitter", "Texture jitter", 0, 100, 5)
  params:add_number("texture_spread", "Texture spread", 0, 100, 5)
  params:add_number("chord_spread", "Chord spread", 0, 100, 2)
  params:add_option("chord_tones_limit", "Chord tones", { "2", "3", "4" }, 2)
  params:add_option("quantize", "Quantize", { "Off", "On" }, 2)
  params:add_option("freeze", "Freeze", { "Off", "On" }, 1)

  params:set_action("grain_size", function(v)
    s.grain_size = v
    EngineAdapter.set_grain_size(v)
  end)
  params:set_action("density", function(v)
    s.density = v
    EngineAdapter.set_density(v)
  end)
  params:set_action("play_speed", function(v)
    s.play_speed = v
    EngineAdapter.set_rate(v)
  end)
  params:set_action("one_shot", function(v)
    s.one_shot = (v == 2)
    if s.one_shot then
      s.continuous = false
    end
  end)
  params:set_action("pitch_range", function(v)
    s.pitch_range = v
  end)
  params:set_action("focus_amount", function(v)
    s.focus_amount = v
  end)
  params:set_action("focus_width", function(v)
    s.focus_width = v
  end)
  params:set_action("focus_time_ms", function(v)
    s.focus_time_ms = v
  end)
  params:set_action("texture_jitter", function(v)
    s.texture_jitter = v
    EngineAdapter.set_jitter(v)
  end)
  params:set_action("texture_spread", function(v)
    s.texture_spread = v
    EngineAdapter.set_spread(v)
  end)
  params:set_action("freeze", function(v)
    s.freeze = (v == 2)
    EngineAdapter.set_freeze(s.freeze)
  end)
  params:set_action("sample_file", function(file)
    if valid_sample_path(file) then
      SampleManager.load(file)
    end
  end)
end

local function maybe_load_default_sample()
  if not params then return false end
  local current = params:get("sample_file")
  if current and current ~= "" and valid_sample_path(current) then
    return false
  end

  for _, path in ipairs(DEFAULT_SAMPLE_PATHS) do
    if valid_sample_path(path) then
      params:set("sample_file", path)
      return true
    end
  end
  return false
end

function init()
  s = State.init()
  _G.chordgrain_state = s

  EngineAdapter.init(s)
  init_params()
  maybe_load_default_sample()
  sync_state_from_params()
  s.scale = Scales.get_scale(s.scale_id)
  s.chord = Chords.get_chord(s.chord_id)
  EngineAdapter.set_grain_size(s.grain_size or 70)
  EngineAdapter.set_density(s.density or 35)
  EngineAdapter.set_rate(s.play_speed or 70)
  EngineAdapter.set_jitter(s.texture_jitter or 5)
  EngineAdapter.set_spread(s.texture_spread or 5)
  EngineAdapter.set_envscale(90)
  EngineAdapter.set_volume(90)
  EngineAdapter.set_freeze(s.freeze or false)
  EngineAdapter.set_position(s.playhead or 0)

  GridBackend.connect(grid_key)

  if tick_metro then tick_metro:stop() end
  tick_metro = metro.init(tick, 1 / 30)
  if tick_metro then tick_metro:start() end
end

function enc(n, d)
  if not s then return end
  handle_enc(n, d)
end

function key(n, z)
  if not s then return end
  handle_key(n, z)
end

function redraw()
  if s then UI.redraw(s) end
end

function cleanup()
  if tick_metro then
    tick_metro:stop()
    tick_metro = nil
  end
  GridBackend.disconnect()
  _G.chordgrain_state = nil
end
