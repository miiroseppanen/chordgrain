-- engine_glut.lua: Glut engine implementation, all calls guarded

local EngineGlut = {}
local continuous_gate_on = false

local MAP = {
  load = "read",
  pos = "seek",
  trig = "gate",
  pitch = "pitch",
  size = "size",
  density = "density",
  jitter = "jitter",
  spread = "spread",
  envscale = "envscale",
  volume = "volume",
  freeze = "freeze",
  rate = "speed",
  voices = "voices",
}

local function safe_call(fn_name, ...)
  if engine and engine[fn_name] then
    return pcall(engine[fn_name], ...)
  end
  return false, "no engine"
end

function EngineGlut.init()
  if engine then
    engine.name = "Glut"
  end
end

local function set_voice_param(fn, value)
  if not engine or not engine[fn] then
    return false, "missing " .. fn
  end
  local ok = true
  for voice = 1, 7 do
    local v_ok = pcall(engine[fn], voice, value)
    ok = ok and v_ok
  end
  return ok, ok and nil or (fn .. " failed")
end

function EngineGlut.load_sample(path)
  if not engine then
    return false, "no engine"
  end

  -- Never call engine.load here: that loads an engine, not a sample file.
  local candidates = {
    MAP.load,
    "loadsample",
    "load_sample",
    "sample",
    "read",
    "set_sample",
    "set_file",
    "file",
  }

  for _, fn in ipairs(candidates) do
    if fn and fn ~= "load" and engine[fn] then
      if fn == "read" then
        local ok = true
        for voice = 1, 7 do
          local v_ok = pcall(engine[fn], voice, path)
          ok = ok and v_ok
        end
        return ok, ok and nil or "read failed"
      end
      return pcall(engine[fn], path)
    end
  end

  return false, "no sample loader"
end

function EngineGlut.set_grain_size(v)
  local fn = MAP.size or "size"
  if not engine or not engine[fn] then
    return false, "no size"
  end
  local ok = true
  for voice = 1, 7 do
    local v_ok = pcall(engine[fn], voice, v / 100)
    ok = ok and v_ok
  end
  return ok, ok and nil or "size failed"
end

function EngineGlut.set_density(v)
  local fn = MAP.density or "density"
  if not engine or not engine[fn] then
    return false, "no density"
  end
  local ok = true
  for voice = 1, 7 do
    local v_ok = pcall(engine[fn], voice, v)
    ok = ok and v_ok
  end
  return ok, ok and nil or "density failed"
end

function EngineGlut.set_jitter(v)
  local fn = MAP.jitter or "jitter"
  return set_voice_param(fn, math.max(0, math.min(1, v / 100)))
end

function EngineGlut.set_spread(v)
  local fn = MAP.spread or "spread"
  return set_voice_param(fn, math.max(0, math.min(1, v / 100)))
end

function EngineGlut.set_envscale(v)
  local fn = MAP.envscale or "envscale"
  return set_voice_param(fn, math.max(0, math.min(1, v / 100)))
end

function EngineGlut.set_volume(v)
  local fn = MAP.volume or "volume"
  return set_voice_param(fn, math.max(0, math.min(1, v / 100)))
end

function EngineGlut.set_freeze(b)
  local fn = MAP.freeze or "freeze"
  return safe_call(fn, b and 1 or 0)
end

function EngineGlut.set_position(pos_norm)
  local fn = MAP.pos or "pos"
  if not engine or not engine[fn] then
    return false, "no seek"
  end
  local ok = true
  for voice = 1, 7 do
    local v_ok = pcall(engine[fn], voice, pos_norm)
    ok = ok and v_ok
  end
  return ok, ok and nil or "seek failed"
end

function EngineGlut.set_rate(v)
  local fn = MAP.rate or "speed"
  return set_voice_param(fn, math.max(0.125, math.min(4, v / 100)))
end

function EngineGlut.play_voice(midi_note, pos_norm, opts)
  opts = opts or {}
  local voice = opts.voice or 1
  local seek_fn = MAP.pos or "seek"
  local pitch_fn = MAP.pitch or "pitch"
  local trig_fn = MAP.trig or "gate"

  if engine and engine[seek_fn] then
    pcall(engine[seek_fn], voice, pos_norm)
  end
  if engine and engine[pitch_fn] then
    local semitones = (midi_note or 60) - 60
    local pitch_range = (opts.pitch_range == nil) and 40 or opts.pitch_range
    local scaled = semitones * math.max(0, math.min(1, pitch_range / 100))
    local pitch_ratio = math.pow(2, scaled / 12)
    pcall(engine[pitch_fn], voice, pitch_ratio)
  end
  if engine and engine[trig_fn] then
    local ok = pcall(engine[trig_fn], voice, 1)
    if opts.one_shot and clock and clock.run then
      local release_s = opts.one_shot_release_s or 0.15
      clock.run(function()
        clock.sleep(release_s)
        pcall(engine[trig_fn], voice, 0)
      end)
    end
    return ok
  end
  return false, "no gate"
end

function EngineGlut.set_continuous(on, midi_note, pos_norm, opts)
  opts = opts or {}
  local voice = opts.voice or 1
  local seek_fn = MAP.pos or "seek"
  local pitch_fn = MAP.pitch or "pitch"
  local trig_fn = MAP.trig or "gate"

  if engine and engine[seek_fn] and pos_norm ~= nil then
    pcall(engine[seek_fn], voice, pos_norm)
  end
  if engine and engine[pitch_fn] then
    local semitones = (midi_note or 60) - 60
    local pitch_range = (opts.pitch_range == nil) and 40 or opts.pitch_range
    local scaled = semitones * math.max(0, math.min(1, pitch_range / 100))
    local pitch_ratio = math.pow(2, scaled / 12)
    pcall(engine[pitch_fn], voice, pitch_ratio)
  end
  if engine and engine[trig_fn] then
    if on and not continuous_gate_on then
      pcall(engine[trig_fn], voice, 1)
      continuous_gate_on = true
    elseif (not on) and continuous_gate_on then
      pcall(engine[trig_fn], voice, 0)
      continuous_gate_on = false
    end
    return true
  end
  return false
end

function EngineGlut.play_chord(notes_midi, pos_norm, opts)
  opts = opts or {}
  local spread = opts.chord_spread or 0.01
  local limit = opts.chord_tones_limit or 3
  for i, note in ipairs(notes_midi) do
    if i > limit then break end
    local offset = (i - 1) * spread
    local pos_i = math.max(0, math.min(1, pos_norm + offset))
    local voice_opts = {
      voice = i,
      one_shot = opts.one_shot,
      one_shot_release_s = opts.one_shot_release_s,
      pitch_range = opts.pitch_range,
    }
    EngineGlut.play_voice(note, pos_i, voice_opts)
  end
end

function EngineGlut.tick(dt, s)
  -- Optional: engine side tick, e.g. for continuous grain triggering
  return true
end

return EngineGlut
