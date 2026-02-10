-- engine_glut.lua: Glut engine implementation, all calls guarded

local EngineGlut = {}

local MAP = {
  load = "read",
  pos = "seek",
  trig = "gate",
  pitch = "pitch",
  size = "size",
  density = "density",
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
    if engine.volume then
      pcall(engine.volume, 1.0)
    end
  end
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
    local v_ok = pcall(engine[fn], voice, v / 100)
    ok = ok and v_ok
  end
  return ok, ok and nil or "density failed"
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
    local pitch_ratio = math.pow(2, ((midi_note or 60) - 60) / 12)
    pcall(engine[pitch_fn], voice, pitch_ratio)
  end
  if engine and engine[trig_fn] then
    return pcall(engine[trig_fn], voice, 1)
  end
  return false, "no gate"
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
    }
    EngineGlut.play_voice(note, pos_i, voice_opts)
  end
end

function EngineGlut.tick(dt, s)
  -- Optional: engine side tick, e.g. for continuous grain triggering
  return true
end

return EngineGlut
