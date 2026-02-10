-- ui.lua: screen rendering for chordgrain

local UI = {}
local Scales = include("lib/scales")
local Chords = include("lib/chords")

local function clip(text, max_len)
  text = tostring(text or "")
  if #text <= max_len then
    return text
  end
  if max_len <= 1 then
    return text:sub(1, max_len)
  end
  return text:sub(1, max_len - 1) .. "."
end

function UI.redraw(s)
  if not screen then return end
  screen.clear()

  local top_y = 6
  local top_x0 = 2
  local top_w = 124
  screen.level(6)
  screen.move(top_x0, top_y)
  screen.line(top_x0 + top_w, top_y)
  screen.stroke()

  local ph_x = top_x0 + (math.max(0, math.min(1, s.playhead or 0)) * top_w)
  screen.level(15)
  screen.move(ph_x, top_y - 3)
  screen.line(ph_x, top_y + 3)
  screen.stroke()
  screen.move(ph_x - 2, top_y)
  screen.line(ph_x + 2, top_y)
  screen.stroke()

  local last_x = top_x0 + (math.max(0, math.min(1, s.last_pos or 0)) * top_w)
  screen.level(9)
  screen.move(last_x, top_y - 2)
  screen.line(last_x, top_y + 2)
  screen.stroke()

  screen.level(15)
  local speed = s.play_speed or 60
  screen.move(0, 16)
  screen.text("Gr " .. tostring(s.grain_size or 0) .. " De " .. tostring(s.density or 0) .. " Sp " .. tostring(speed))

  local scale = Scales.get_scale(s.scale_id or 1)
  local chord = Chords.get_chord(s.chord_id or 1)
  screen.level(10)
  screen.move(0, 24)
  screen.text("Sc " .. clip(scale and scale.name or "-", 8) .. " Ch " .. clip(chord and chord.name or "-", 8))

  local root_name = Scales.root_name(s.root or 0)
  local note_str = s.last_note and Scales.midi_to_note_name(s.last_note) or ""
  screen.move(0, 32)
  screen.text("Rt " .. root_name .. " Oc " .. tostring(s.octave or 3) .. " Nt " .. clip(note_str ~= "" and note_str or "-", 6))

  local pos_pct = math.floor((s.playhead or 0) * 100)
  screen.move(0, 40)
  screen.text("Pos " .. tostring(pos_pct) .. "% C " .. (s.continuous and "On" or "Off") .. " F " .. (s.freeze and "On" or "Off"))

  screen.move(0, 48)
  screen.text("Sm " .. clip((s.sample_name and s.sample_name ~= "" and s.sample_name or "none"), 18))

  screen.update()
end

return UI
