-- engine_glut.lua: Glut engine implementation, all calls guarded

local EngineGlut = {}

local MAP = {
  load = "load",
  pos = "pos",
  trig = "trig",
  size = "size",
  density = "density",
  freeze = "freeze",
  rate = "rate",
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

function EngineGlut.load_sample(path)
  local fn = MAP.load or "load"
  return safe_call(fn, path)
end

function EngineGlut.set_grain_size(v)
  local fn = MAP.size or "size"
  return safe_call(fn, v)
end

function EngineGlut.set_density(v)
  local fn = MAP.density or "density"
  return safe_call(fn, v)
end

function EngineGlut.set_freeze(b)
  local fn = MAP.freeze or "freeze"
  return safe_call(fn, b and 1 or 0)
end

function EngineGlut.set_position(pos_norm)
  local fn = MAP.pos or "pos"
  return safe_call(fn, pos_norm)
end

function EngineGlut.play_voice(midi_note, pos_norm, opts)
  local fn = MAP.trig or "trig"
  return safe_call(fn, midi_note, pos_norm)
end

function EngineGlut.play_chord(notes_midi, pos_norm, opts)
  opts = opts or {}
  local spread = opts.chord_spread or 0.01
  local limit = opts.chord_tones_limit or 3
  for i, note in ipairs(notes_midi) do
    if i > limit then break end
    local offset = (i - 1) * spread
    local pos_i = math.max(0, math.min(1, pos_norm + offset))
    EngineGlut.play_voice(note, pos_i, opts)
  end
end

function EngineGlut.tick(dt, s)
  -- Optional: engine side tick, e.g. for continuous grain triggering
  return true
end

return EngineGlut
