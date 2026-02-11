-- engine_adapter.lua: single point for all engine calls, fails gracefully

local EngineAdapter = {}
local EngineGlut = include("lib/engine_glut")
local EngineSoftcut = include("lib/engine_softcut")

local PLAY_MODE_GRAIN = 1
local PLAY_MODE_SAMPLER = 2
local current_mode = PLAY_MODE_GRAIN

local function active_backend()
  if current_mode == PLAY_MODE_SAMPLER then
    return EngineSoftcut
  end
  return EngineGlut
end

local function call_backend(fn_name, ...)
  local backend = active_backend()
  if not backend then
    return false
  end
  local fn = backend[fn_name]
  if not fn then
    return false
  end
  return fn(...)
end

function EngineAdapter.set_mode(play_mode_id)
  current_mode = play_mode_id or PLAY_MODE_GRAIN
end

function EngineAdapter.init(s)
  EngineAdapter.set_mode(s and s.play_mode_id or PLAY_MODE_GRAIN)
  EngineGlut.init()
  EngineSoftcut.init()
  return true
end

function EngineAdapter.load_sample(path)
  if not path or path == "" then return false end
  local ok
  if current_mode == PLAY_MODE_SAMPLER then
    ok = call_backend("load_sample", path)
    if not ok then
      ok = EngineGlut.load_sample(path)
    end
  else
    ok = call_backend("load_sample", path)
  end
  if not ok then return false end
  return true
end

function EngineAdapter.set_grain_size(v)
  call_backend("set_grain_size", v)
end

function EngineAdapter.set_density(v)
  call_backend("set_density", v)
end

function EngineAdapter.set_jitter(v)
  call_backend("set_jitter", v)
end

function EngineAdapter.set_spread(v)
  call_backend("set_spread", v)
end

function EngineAdapter.set_envscale(v)
  call_backend("set_envscale", v)
end

function EngineAdapter.set_volume(v)
  call_backend("set_volume", v)
end

function EngineAdapter.set_rate(v)
  call_backend("set_rate", v)
end

function EngineAdapter.set_freeze(b)
  call_backend("set_freeze", b)
end

function EngineAdapter.set_position(pos_norm)
  pos_norm = math.max(0, math.min(1, pos_norm))
  call_backend("set_position", pos_norm)
end

function EngineAdapter.play_chord(notes_midi, pos_norm, opts)
  if not notes_midi or #notes_midi == 0 then return end
  pos_norm = math.max(0, math.min(1, pos_norm or 0))
  call_backend("play_chord", notes_midi, pos_norm, opts)
end

function EngineAdapter.tick(dt, s)
  return call_backend("tick", dt, s)
end

return EngineAdapter
