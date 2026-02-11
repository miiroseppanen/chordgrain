-- gridmap.lua: 16x8 grid mapping and LED rendering

local GridMap = {}
local Scales = include("lib/scales")
local Chords = include("lib/chords")

function GridMap.key_to_scale_id(x, y)
  if y ~= 1 then return nil end
  return math.max(1, math.min(x, 16))
end

function GridMap.key_to_chord_id(x, y)
  if y ~= 2 then return nil end
  return math.max(1, math.min(x, 16))
end

local function row_base_midi(y)
  return 60 + ((4 - y) * 12)
end

function GridMap.key_to_note(x, y)
  if y < 3 or y > 8 then return nil, false end
  if x >= 13 and x <= 16 then
    return nil, true
  end
  if x < 1 or x > 12 then
    return nil, false
  end
  local midi = row_base_midi(y) + (x - 1)
  return midi, false
end

function GridMap.midi_to_key(midi)
  if not midi then return nil, nil end
  for y = 3, 8 do
    local base = row_base_midi(y)
    if midi >= base and midi <= (base + 11) then
      return (midi - base) + 1, y
    end
  end
  return nil, nil
end

-- LED level policy
-- selected controls: 15
-- inactive controls: 3
-- last trigger marker: 10
-- continuous playhead marker: 4
-- chord tones: 8
function GridMap.render_leds(g, s)
  if not g then return end
  g:all(0)

  local scale_id = s.scale_id or 1
  local chord_id = s.chord_id or 1
  local continuous = s.continuous or false
  local playhead = s.playhead or 0
  local last_pos = s.last_pos or 0

  for x = 1, 16 do
    if x == scale_id then
      g:led(x, 1, 15)
    else
      g:led(x, 1, 3)
    end
  end

  for x = 1, 16 do
    if x == chord_id then
      g:led(x, 2, 15)
    else
      g:led(x, 2, 3)
    end
  end

  -- six row keyboard with octave per row.
  -- x13 to x16 are overflow keys reserved for future use.
  for y = 3, 8 do
    for x = 13, 16 do
      g:led(x, y, 11)
    end
  end

  local last_x = math.floor(last_pos * 15) + 1
  last_x = math.max(1, math.min(16, last_x))
  g:led(last_x, 8, 10)

  if continuous then
    local head_x = math.floor(playhead * 15) + 1
    head_x = math.max(1, math.min(16, head_x))
    g:led(head_x, 8, 4)
  end

  if s.last_chord_notes then
    for _, midi in ipairs(s.last_chord_notes) do
      local x, y = GridMap.midi_to_key(math.floor((midi or 0) + 0.5))
      if x and y then
        g:led(x, y, 8)
      end
    end
  end

  if s.last_note then
    local px, py = GridMap.midi_to_key(math.floor((s.last_note or 0) + 0.5))
    if px and py then
      g:led(px, py, 15)
    end
  end
end

return GridMap
