-- chords.lua: chord definitions and interval lists

local Chords = {}

Chords.list = {
  { name = "Major", intervals = { 0, 4, 7 } },
  { name = "Minor", intervals = { 0, 3, 7 } },
  { name = "Major7", intervals = { 0, 4, 7, 11 } },
  { name = "Minor7", intervals = { 0, 3, 7, 10 } },
  { name = "Dominant7", intervals = { 0, 4, 7, 10 } },
  { name = "Diminished", intervals = { 0, 3, 6 } },
  { name = "Augmented", intervals = { 0, 4, 8 } },
  { name = "Sus2", intervals = { 0, 2, 7 } },
  { name = "Sus4", intervals = { 0, 5, 7 } },
  { name = "Power", intervals = { 0, 7 } },
  { name = "Major6", intervals = { 0, 4, 7, 9 } },
  { name = "Minor6", intervals = { 0, 3, 7, 9 } },
  { name = "Major9", intervals = { 0, 4, 7, 11, 14 } },
  { name = "Minor9", intervals = { 0, 3, 7, 10, 14 } },
  { name = "None", intervals = {} },
  { name = "Unison", intervals = { 0 } },
}

function Chords.get_chord(id)
  local idx = math.max(1, math.min(id, #Chords.list))
  return Chords.list[idx]
end

function Chords.chord_notes(root_midi, chord_intervals, limit)
  if not chord_intervals or #chord_intervals == 0 then
    return { root_midi }
  end
  limit = limit or 4
  local notes = {}
  for i = 1, math.min(limit, #chord_intervals) do
    local interval = chord_intervals[i]
    local oct = math.floor(interval / 12)
    local sem = interval % 12
    notes[#notes + 1] = root_midi + oct * 12 + sem
  end
  return notes
end

return Chords
