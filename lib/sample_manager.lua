-- sample_manager.lua: sample path and loading via EngineAdapter

local SampleManager = {}
local EngineAdapter = include("lib/engine_adapter")

function SampleManager.load(file)
  if not file or file == "" then return end
  local s = _G.chordgrain_state
  if s then
    s.sample_path = file
    s.sample_name = string.match(file, "([^/\\]+)$") or file
  end
  EngineAdapter.load_sample(file)
end

return SampleManager
