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

function GridMap.key_to_root(x, y)
  if y ~= 3 then return nil end
  if x >= 1 and x <= 12 then
    return x - 1, nil
  end
  if x >= 13 and x <= 16 then
    return nil, (x - 13) + 2
  end
  return nil, nil
end

function GridMap.key_to_play(x, y)
  if y < 4 or y > 8 then return nil, nil end
  local row_index = y - 4
  local pos_norm = (x - 1) / 15
  local degree = 1 + row_index * 16 + (x - 1)
  return pos_norm, degree
end

function GridMap.degree_to_key(degree)
  if not degree or degree < 1 then return nil, nil end
  local idx = degree - 1
  local row_index = math.floor(idx / 16)
  local col_index = idx % 16
  if row_index < 0 or row_index > 4 then return nil, nil end
  return col_index + 1, row_index + 4
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
  local root = s.root or 0
  local octave = s.octave or 3
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

  for x = 1, 12 do
    g:led(x, 3, root == (x - 1) and 15 or 3)
  end
  for x = 13, 16 do
    local oct = (x - 13) + 2
    g:led(x, 3, octave == oct and 15 or 3)
  end

  local last_x = math.floor(last_pos * 15) + 1
  last_x = math.max(1, math.min(16, last_x))
  g:led(last_x, 8, 10)

  if continuous then
    local head_x = math.floor(playhead * 15) + 1
    head_x = math.max(1, math.min(16, head_x))
    g:led(head_x, 8, 4)
  end

  if s.last_chord_degrees then
    for _, degree in ipairs(s.last_chord_degrees) do
      local x, y = GridMap.degree_to_key(degree)
      if x and y then
        g:led(x, y, 8)
      end
    end
  end

  if s.pressed_degree then
    local px, py = GridMap.degree_to_key(s.pressed_degree)
    if px and py then
      g:led(px, py, 15)
    end
  end
end

return GridMap
