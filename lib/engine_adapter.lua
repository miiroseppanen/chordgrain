-- engine_adapter.lua: single point for all engine calls, fails gracefully

local EngineAdapter = {}
local EngineGlut = include("lib/engine_glut")

function EngineAdapter.init(s)
  EngineGlut.init()
  return true
end

function EngineAdapter.load_sample(path)
  if not path or path == "" then return false end
  local ok, err = EngineGlut.load_sample(path)
  if not ok then return false end
  return true
end

function EngineAdapter.set_grain_size(v)
  EngineGlut.set_grain_size(v)
end

function EngineAdapter.set_density(v)
  EngineGlut.set_density(v)
end

function EngineAdapter.set_jitter(v)
  EngineGlut.set_jitter(v)
end

function EngineAdapter.set_spread(v)
  EngineGlut.set_spread(v)
end

function EngineAdapter.set_envscale(v)
  EngineGlut.set_envscale(v)
end

function EngineAdapter.set_volume(v)
  EngineGlut.set_volume(v)
end

function EngineAdapter.set_rate(v)
  EngineGlut.set_rate(v)
end

function EngineAdapter.set_freeze(b)
  EngineGlut.set_freeze(b)
end

function EngineAdapter.set_position(pos_norm)
  pos_norm = math.max(0, math.min(1, pos_norm))
  EngineGlut.set_position(pos_norm)
end

function EngineAdapter.play_chord(notes_midi, pos_norm, opts)
  if not notes_midi or #notes_midi == 0 then return end
  pos_norm = math.max(0, math.min(1, pos_norm or 0))
  EngineGlut.play_chord(notes_midi, pos_norm, opts)
end

function EngineAdapter.tick(dt, s)
  return EngineGlut.tick(dt, s)
end

return EngineAdapter
