-- chordgrain.lua: grid focused chord aware granular sampler

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

local function sync_state_from_params()
  s.grain_size = params:get("grain_size")
  s.density = params:get("density")
  s.freeze = params:get("freeze") == 2
  s.quantize = params:get("quantize") == 2
  s.chord_spread = params:get("chord_spread") / 100
  s.chord_tones_limit = (params:get("chord_tones_limit") or 2) + 1
  s.scale = Scales.get_scale(s.scale_id)
  s.chord = Chords.get_chord(s.chord_id)
end

local function trigger_at(pos_norm, degree)
  sync_state_from_params()
  local midi = Scales.degree_to_midi(degree, s.root, s.octave, s.scale and s.scale.intervals, s.quantize)
  local chord = s.chord
  local intervals = chord and chord.intervals or { 0 }
  local limit = s.chord_tones_limit or 3
  local notes = Chords.chord_notes(midi, intervals, limit)
  local opts = {
    chord_spread = s.chord_spread or 0.08,
    chord_tones_limit = limit,
  }
  EngineAdapter.play_chord(notes, pos_norm, opts)
  s.last_note = midi
  s.last_pos = pos_norm
  s.playhead = pos_norm
  EngineAdapter.set_position(pos_norm)
end

local function grid_key(g, x, y, z)
  if z == 0 then return end
  local scale_id = GridMap.key_to_scale_id(x, y)
  if scale_id then
    s.scale_id = scale_id
    s.scale = Scales.get_scale(scale_id)
    return
  end
  local chord_id = GridMap.key_to_chord_id(x, y)
  if chord_id then
    s.chord_id = chord_id
    s.chord = Chords.get_chord(chord_id)
    return
  end
  local root, oct = GridMap.key_to_root(x, y)
  if root ~= nil then
    s.root = root
    return
  end
  if oct ~= nil then
    s.octave = oct
    return
  end
  local pos_norm, degree = GridMap.key_to_play(x, y)
  if pos_norm and degree then
    trigger_at(pos_norm, degree)
  end
end

local function enc(n, d)
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

local function key(n, z)
  if z == 0 then return end
  if n == 1 then return end
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

  if s.continuous and not s.freeze then
    local speed_pct = params:get("play_speed") or 60
    local advance = (speed_pct / 60 / 60) * dt
    s.playhead = s.playhead + advance
    if s.playhead >= 1 then s.playhead = s.playhead - 1 end
    if s.playhead < 0 then s.playhead = s.playhead + 1 end
    EngineAdapter.set_position(s.playhead)
  end

  EngineAdapter.tick(dt, s)
  GridBackend.render(GridMap.render_leds, s)
  UI.redraw(s)
end

local function init_params()
  if not params then return end
  params:add_group("chordgrain", "chordgrain", 7)
  params:add_number("grain_size", "Grain size", 1, 100, 30)
  params:add_number("density", "Density", 1, 100, 40)
  params:add_number("play_speed", "Play speed", 1, 200, 60)
  params:add_file("sample_file", "Sample")
  params:add_number("chord_spread", "Chord spread", 0, 100, 8)
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
  params:set_action("freeze", function(v)
    s.freeze = (v == 2)
    EngineAdapter.set_freeze(s.freeze)
  end)
  params:set_action("sample_file", function(file)
    if file and file ~= "" then
      SampleManager.load(file)
    end
  end)
end

function init()
  s = State.init()
  _G.chordgrain_state = s
  if engine then
    engine.name = "Glut"
  end

  EngineAdapter.init(s)
  init_params()
  sync_state_from_params()
  s.scale = Scales.get_scale(s.scale_id)
  s.chord = Chords.get_chord(s.chord_id)

  GridBackend.connect(grid_key)

  if tick_metro then tick_metro:stop() end
  tick_metro = metro.init(tick, 1 / 30)
  if tick_metro then tick_metro:start() end
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
