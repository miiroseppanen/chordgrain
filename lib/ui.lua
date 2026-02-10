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
  screen.level(15)
  screen.move(0, 8)
  screen.text("chordgrain G" .. tostring(s.grain_size or 0) .. " D" .. tostring(s.density or 0))

  local scale = Scales.get_scale(s.scale_id or 1)
  local chord = Chords.get_chord(s.chord_id or 1)
  screen.level(10)
  screen.move(0, 16)
  screen.text("Sc " .. clip(scale and scale.name or "-", 8) .. " Ch " .. clip(chord and chord.name or "-", 8))

  local root_name = Scales.root_name(s.root or 0)
  local note_str = s.last_note and Scales.midi_to_note_name(s.last_note) or ""
  screen.move(0, 24)
  screen.text("Rt " .. root_name .. tostring(s.octave or 3) .. " Nt " .. clip(note_str ~= "" and note_str or "-", 8))

  local chord_notes = {}
  if s.last_chord_notes then
    for i, midi in ipairs(s.last_chord_notes) do
      if i > 4 then break end
      chord_notes[#chord_notes + 1] = Scales.midi_to_note_name(midi)
    end
  end
  local chord_note_str = (#chord_notes > 0) and table.concat(chord_notes, " ") or "-"
  screen.move(0, 32)
  screen.text("CN " .. clip(chord_note_str, 18))

  local pos_pct = math.floor((s.playhead or 0) * 100)
  screen.move(0, 40)
  screen.text("Pos " .. tostring(pos_pct) .. "% C " .. (s.continuous and "On" or "Off") .. " F " .. (s.freeze and "On" or "Off"))

  screen.move(0, 48)
  screen.text("Sm " .. clip((s.sample_name and s.sample_name ~= "" and s.sample_name or "none"), 18))

  local help_a = "N E1 pos E2 gr E3 den"
  local help_b = "N K2 cont K3 freeze"
  local help_c = "G r1 sc r2 ch r3 rt r4-8 play"
  local help_idx = 0
  if util and util.time then
    help_idx = math.floor(util.time() / 2) % 3
  end
  local help_line = help_a
  if help_idx == 1 then
    help_line = help_b
  elseif help_idx == 2 then
    help_line = help_c
  end
  screen.level(5)
  screen.move(0, 56)
  screen.text(clip(help_line, 24))

  local bar_y = 60
  local bar_w = 128
  screen.level(8)
  screen.move(0, bar_y)
  screen.line(bar_w, bar_y)
  screen.stroke()

  local playhead_x = (s.playhead or 0) * (bar_w - 2) + 1
  screen.level(15)
  screen.move(playhead_x, bar_y - 2)
  screen.line(playhead_x, bar_y + 2)
  screen.stroke()

  local last_x = (s.last_pos or 0) * (bar_w - 2) + 1
  screen.level(10)
  screen.move(last_x, bar_y - 3)
  screen.line(last_x, bar_y + 3)
  screen.stroke()

  screen.update()
end

return UI
