-- ui.lua: screen rendering for chordgrain

local UI = {}
local Scales = include("lib/scales")
local Chords = include("lib/chords")

function UI.redraw(s)
  if not screen then return end
  screen.clear()
  screen.level(15)
  screen.move(0, 10)
  screen.text("chordgrain")
  screen.level(5)
  screen.move(0, 22)
  screen.text("Grain: " .. tostring(s.grain_size or 0))
  screen.move(0, 32)
  screen.text("Density: " .. tostring(s.density or 0))

  local scale = Scales.get_scale(s.scale_id or 1)
  local chord = Chords.get_chord(s.chord_id or 1)
  screen.move(0, 44)
  screen.text("Scale: " .. (scale and scale.name or ""))
  screen.move(0, 54)
  screen.text("Chord: " .. (chord and chord.name or ""))

  local root_name = Scales.root_name(s.root or 0)
  screen.move(0, 64)
  screen.text("Root: " .. root_name .. " Octave: " .. tostring(s.octave or 3))

  local note_str = s.last_note and Scales.midi_to_note_name(s.last_note) or ""
  screen.move(0, 74)
  screen.text("Note: " .. note_str)

  local pos_pct = math.floor((s.playhead or 0) * 100)
  screen.move(0, 84)
  screen.text("Position: " .. tostring(pos_pct) .. "%")

  screen.move(0, 94)
  screen.text("Continuous: " .. (s.continuous and "On" or "Off"))
  screen.move(0, 104)
  screen.text("Freeze: " .. (s.freeze and "On" or "Off"))

  screen.move(0, 114)
  screen.text("Sample: " .. (s.sample_name and s.sample_name ~= "" and s.sample_name or "none"))

  local bar_y = 120
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
