-- engine_softcut.lua: Softcut sampler style backend

local EngineSoftcut = {}

local MAX_VOICES = 4
local BUFFER_ID = 1

local state = {
  sample_loaded = false,
  sample_duration = 8.0,
  play_rate = 1.0,
  frozen = false,
}

local function safe_call(fn, ...)
  if not softcut or not softcut[fn] then
    return false, "no softcut." .. fn
  end
  return pcall(softcut[fn], ...)
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function setup_voice(voice)
  safe_call("enable", voice, 1)
  safe_call("buffer", voice, BUFFER_ID)
  safe_call("level", voice, 0.85)
  safe_call("pan", voice, 0)
  safe_call("loop", voice, 1)
  safe_call("loop_start", voice, 0)
  safe_call("loop_end", voice, state.sample_duration)
  safe_call("position", voice, 0)
  safe_call("fade_time", voice, 0.01)
  safe_call("rate_slew_time", voice, 0.03)
  safe_call("play", voice, state.frozen and 0 or 1)
end

function EngineSoftcut.init()
  if not softcut then
    return false, "no softcut"
  end
  for voice = 1, MAX_VOICES do
    setup_voice(voice)
  end
  return true
end

function EngineSoftcut.load_sample(path)
  if not softcut or not path or path == "" then
    return false, "no softcut or path"
  end

  local channels, frames, sr = audio.file_info(path)
  if not frames or not sr or sr <= 0 then
    return false, "invalid file info"
  end
  local duration = math.max(0.05, frames / sr)
  state.sample_duration = duration

  for voice = 1, MAX_VOICES do
    setup_voice(voice)
  end

  -- clear first to avoid stale content in buffer
  pcall(softcut.buffer_clear)
  local ok = pcall(softcut.buffer_read_mono, path, 0, 0, duration, 1, BUFFER_ID)
  if not ok then
    return false, "buffer_read_mono failed"
  end

  for voice = 1, MAX_VOICES do
    safe_call("loop_end", voice, duration)
    safe_call("position", voice, 0)
  end

  state.sample_loaded = true
  return true
end

function EngineSoftcut.set_grain_size(v)
  return true
end

function EngineSoftcut.set_density(v)
  return true
end

function EngineSoftcut.set_jitter(v)
  return true
end

function EngineSoftcut.set_spread(v)
  return true
end

function EngineSoftcut.set_envscale(v)
  return true
end

function EngineSoftcut.set_volume(v)
  local level = clamp((v or 90) / 100, 0, 1.2)
  for voice = 1, MAX_VOICES do
    safe_call("level", voice, level)
  end
  return true
end

function EngineSoftcut.set_rate(v)
  state.play_rate = clamp((v or 100) / 100, 0.25, 2.0)
  return true
end

function EngineSoftcut.set_freeze(b)
  state.frozen = b and true or false
  local play = state.frozen and 0 or 1
  for voice = 1, MAX_VOICES do
    safe_call("play", voice, play)
  end
  return true
end

function EngineSoftcut.set_position(pos_norm)
  if not state.sample_loaded then
    return false, "no sample"
  end
  local pos = clamp(pos_norm or 0, 0, 1) * state.sample_duration
  for voice = 1, MAX_VOICES do
    safe_call("position", voice, pos)
  end
  return true
end

function EngineSoftcut.play_chord(notes_midi, pos_norm, opts)
  if not notes_midi or #notes_midi == 0 or not state.sample_loaded then
    return false
  end
  opts = opts or {}
  local tones = math.min(#notes_midi, MAX_VOICES, opts.chord_tones_limit or MAX_VOICES)
  local pr = clamp((opts.pitch_range or 40) / 100, 0, 1)
  local base_pos = clamp(pos_norm or 0, 0, 1) * state.sample_duration

  for i = 1, tones do
    local note = notes_midi[i] or 60
    local semitones = (note - 60) * pr
    local ratio = math.pow(2, semitones / 12)
    local rate = ratio * state.play_rate

    safe_call("position", i, base_pos)
    safe_call("rate", i, rate)
    safe_call("play", i, state.frozen and 0 or 1)
  end
  return true
end

function EngineSoftcut.tick(dt, s)
  return true
end

return EngineSoftcut
