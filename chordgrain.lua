-- chordgrain
-- granular chord sampler
-- norns: E1 pos E2 grain E3 den
-- norns: K1 menu K2 cont K3 freeze
-- grid: r1 scale r2 chord
-- grid: r3-8 note keys, 6 octaves

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
local last_trigger_midi

local DEFAULT_SAMPLE_PATHS = {
  "/home/we/dust/audio/hermit_leaves.wav",
  "/home/we/dust/audio/common/hermit_leaves.wav",
}
local PLAY_MODE_GRAIN = 1
local PLAY_MODE_SAMPLER = 2

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
  s.sampler_density = params:get("sampler_density")
  s.play_mode_id = params:get("play_mode")
  s.play_speed = params:get("play_speed")
  s.one_shot = params:get("one_shot") == 2
  s.pitch_range = params:get("pitch_range")
  s.sampler_pitch_range = params:get("sampler_pitch_range")
  s.sampler_chord_scale = params:get("sampler_chord_scale")
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

local function is_sampler_mode()
  return (s.play_mode_id or PLAY_MODE_GRAIN) == PLAY_MODE_SAMPLER
end

local function apply_play_mode_engine_state()
  if is_sampler_mode() then
    -- Sampler style: stable cloud with note pitch separate from transport.
    EngineAdapter.set_grain_size(85)
    EngineAdapter.set_density(s.sampler_density or 65)
    EngineAdapter.set_jitter(0)
    EngineAdapter.set_spread(0)
    EngineAdapter.set_envscale(100)
    EngineAdapter.set_rate(100)
  else
    EngineAdapter.set_grain_size(s.grain_size or 70)
    EngineAdapter.set_density(s.density or 28)
    EngineAdapter.set_jitter(s.texture_jitter or 5)
    EngineAdapter.set_spread(s.texture_spread or 5)
    EngineAdapter.set_envscale(90)
    EngineAdapter.set_rate(s.play_speed or 100)
  end
  EngineAdapter.set_volume(90)
end

local function focus_center_from_pos(pos_norm)
  local amount = clamp((s.focus_amount or 0) / 100, 0, 1)
  return clamp((pos_norm * (1 - amount)) + (0.5 * amount), 0, 1)
end

local function trigger_note_at(pos_norm, midi)
  sync_state_from_params()
  pos_norm = clamp(pos_norm or 0, 0, 1)
  midi = math.floor((midi or 60) + 0.5)
  local chord = s.chord
  local intervals = chord and chord.intervals or { 0 }
  local limit = s.chord_tones_limit or 3
  local notes
  if is_sampler_mode() then
    notes = Chords.chord_notes_scaled(midi, intervals, limit, s.sampler_chord_scale or 30)
  else
    notes = Chords.chord_notes(midi, intervals, limit)
  end
  local opts = {
    chord_spread = is_sampler_mode() and 0 or (s.chord_spread or 0.02),
    chord_tones_limit = limit,
    one_shot = s.one_shot,
    one_shot_release_s = 0.20,
    pitch_range = is_sampler_mode() and (s.sampler_pitch_range or 32) or (s.pitch_range or 60),
  }
  local focused_pos = is_sampler_mode() and pos_norm or focus_center_from_pos(pos_norm)
  EngineAdapter.play_chord(notes, focused_pos, opts)
  s.focus_center = focused_pos
  s.focus_phase = 0
  s.focus_until = util.time() + ((s.focus_time_ms or 0) / 1000)
  s.focus_active = (not is_sampler_mode()) and (s.focus_amount or 0) > 0 and (s.focus_time_ms or 0) > 0
  s.last_note = midi
  s.last_pos = focused_pos
  s.pressed_degree = nil
  s.last_chord_notes = notes
  s.last_chord_degrees = {}
  last_trigger_midi = midi
  EngineAdapter.set_position(focused_pos)
  if is_sampler_mode() and s.continuous and not s.one_shot and not s.freeze then
    EngineAdapter.set_continuous(true, midi, focused_pos, {
      pitch_range = s.sampler_pitch_range or 32,
      voice = 1,
    })
  end
end

local function retrigger_current_selection()
  if not s or not last_trigger_midi then
    return
  end
  local pos = s.last_pos
  if pos == nil then
    pos = s.playhead or s.scrub or 0
  end
  trigger_note_at(pos, last_trigger_midi)
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
  local midi, overflow = GridMap.key_to_note(x, y)
  if overflow then
    return
  end
  if midi then
    local pos = s.playhead or s.scrub or 0
    trigger_note_at(pos, midi)
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
      if is_sampler_mode() and not s.one_shot then
        local note = s.last_note or 60
        EngineAdapter.set_continuous(true, note, s.playhead, {
          pitch_range = s.sampler_pitch_range or 32,
          voice = 1,
        })
      end
    else
      EngineAdapter.set_continuous(false, s.last_note or 60, s.playhead, { voice = 1 })
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
    local advance
    if is_sampler_mode() then
      -- Sampler mode uses direct transport: percent of sample per second.
      advance = (speed_pct / 100) * dt
    else
      -- Grain mode keeps slow scan behavior.
      advance = (speed_pct / 60 / 60) * dt
    end
    s.playhead = s.playhead + advance
    if s.playhead >= 1 then s.playhead = s.playhead - 1 end
    if s.playhead < 0 then s.playhead = s.playhead + 1 end
    EngineAdapter.set_position(s.playhead)
    if is_sampler_mode() then
      local note = s.last_note or 60
      EngineAdapter.set_continuous(true, note, s.playhead, {
        pitch_range = s.sampler_pitch_range or 32,
        voice = 1,
      })
    end

  end

  if (not is_sampler_mode()) or (not s.continuous) or s.one_shot or s.freeze then
    EngineAdapter.set_continuous(false, s.last_note or 60, s.playhead, { voice = 1 })
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
  params:add_option("play_mode", "Play mode", { "Grain", "Sampler" }, 2)
  params:add_number("grain_size", "Grain size", 1, 100, 70)
  params:add_number("density", "Density", 1, 100, 28)
  params:add_number("sampler_density", "Sampler density", 1, 100, 65)
  params:add_number("play_speed", "Play speed", 1, 200, 20)
  params:add_option("one_shot", "One shot mode", { "Off", "On" }, 1)
  params:add_number("pitch_range", "Pitch range", 0, 100, 60)
  params:add_number("sampler_pitch_range", "Sampler pitch", 0, 100, 32)
  params:add_number("sampler_chord_scale", "Sampler chord", 0, 100, 30)
  params:add_number("focus_amount", "Focus amount", 0, 100, 0)
  params:add_number("focus_width", "Focus width", 1, 50, 12)
  params:add_number("focus_time_ms", "Focus time ms", 0, 2000, 420)
  params:add_number("texture_jitter", "Texture jitter", 0, 100, 5)
  params:add_number("texture_spread", "Texture spread", 0, 100, 5)
  params:add_number("chord_spread", "Chord spread", 0, 100, 2)
  params:add_option("chord_tones_limit", "Chord tones", { "2", "3", "4" }, 2)
  params:add_option("quantize", "Quantize", { "Off", "On" }, 2)
  params:add_option("freeze", "Freeze", { "Off", "On" }, 1)

  params:set_action("play_mode", function(v)
    s.play_mode_id = v
    EngineAdapter.set_continuous(false, s.last_note or 60, s.playhead, { voice = 1 })
    if v == PLAY_MODE_SAMPLER then
      params:set("one_shot", 1)
      s.one_shot = false
      s.continuous = true
      params:set("focus_amount", 0)
      s.focus_amount = 0
      if s.sample_path and s.sample_path ~= "" then
        EngineAdapter.load_sample(s.sample_path)
      end
    else
      if s.sample_path and s.sample_path ~= "" then
        EngineAdapter.load_sample(s.sample_path)
      end
    end
    apply_play_mode_engine_state()
  end)
  params:set_action("grain_size", function(v)
    s.grain_size = v
    if not is_sampler_mode() then
      EngineAdapter.set_grain_size(v)
    end
  end)
  params:set_action("density", function(v)
    s.density = v
    if not is_sampler_mode() then
      EngineAdapter.set_density(v)
    end
  end)
  params:set_action("sampler_density", function(v)
    s.sampler_density = v
    if is_sampler_mode() then
      EngineAdapter.set_density(v)
    end
  end)
  params:set_action("play_speed", function(v)
    s.play_speed = v
    if not is_sampler_mode() then
      EngineAdapter.set_rate(v)
    end
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
  params:set_action("sampler_pitch_range", function(v)
    s.sampler_pitch_range = v
  end)
  params:set_action("sampler_chord_scale", function(v)
    s.sampler_chord_scale = v
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
    if not is_sampler_mode() then
      EngineAdapter.set_jitter(v)
    end
  end)
  params:set_action("texture_spread", function(v)
    s.texture_spread = v
    if not is_sampler_mode() then
      EngineAdapter.set_spread(v)
    end
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
  s.continuous = true
  apply_play_mode_engine_state()
  EngineAdapter.set_freeze(s.freeze or false)
  EngineAdapter.set_position(s.playhead or 0)
  if is_sampler_mode() and not s.one_shot then
    EngineAdapter.set_continuous(true, 60, s.playhead or 0, {
      pitch_range = s.sampler_pitch_range or 32,
      voice = 1,
    })
  end

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
  EngineAdapter.set_continuous(false, s and s.last_note or 60, s and s.playhead or 0, { voice = 1 })
  if tick_metro then
    tick_metro:stop()
    tick_metro = nil
  end
  GridBackend.disconnect()
  _G.chordgrain_state = nil
end
