-- scales.lua: scale definitions and degree to midi conversion

local Scales = {}

Scales.list = {
  { name = "Major", intervals = { 0, 2, 4, 5, 7, 9, 11 } },
  { name = "Minor", intervals = { 0, 2, 3, 5, 7, 8, 10 } },
  { name = "Dorian", intervals = { 0, 2, 3, 5, 7, 9, 10 } },
  { name = "Phrygian", intervals = { 0, 1, 3, 5, 7, 8, 10 } },
  { name = "Lydian", intervals = { 0, 2, 4, 6, 7, 9, 11 } },
  { name = "Mixolydian", intervals = { 0, 2, 4, 5, 7, 9, 10 } },
  { name = "Locrian", intervals = { 0, 1, 3, 5, 6, 8, 10 } },
  { name = "Pentatonic", intervals = { 0, 2, 4, 7, 9 } },
  { name = "Blues", intervals = { 0, 3, 5, 6, 7, 10 } },
  { name = "Chromatic", intervals = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 } },
  { name = "Whole tone", intervals = { 0, 2, 4, 6, 8, 10 } },
  { name = "Diminished", intervals = { 0, 1, 3, 4, 6, 7, 9, 10 } },
}

local ROOT_NAMES = {
  "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
}

function Scales.get_scale(id)
  local idx = math.max(1, math.min(id, #Scales.list))
  return Scales.list[idx]
end

function Scales.degree_to_midi(degree, root_semitone, octave_base, scale_intervals, quantize)
  if quantize == false then
    return (octave_base + 1) * 12 + root_semitone + (degree - 1)
  end
  if not scale_intervals or #scale_intervals == 0 then
    scale_intervals = { 0, 2, 4, 5, 7, 9, 11 }
  end
  degree = degree - 1
  local num_degrees = #scale_intervals
  local octave_offset = math.floor(degree / num_degrees)
  local degree_in_oct = degree % num_degrees
  local semitone = scale_intervals[degree_in_oct + 1] + root_semitone
  local midi = (octave_base + 1) * 12 + semitone + octave_offset * 12
  return midi
end

function Scales.midi_to_note_name(midi)
  if midi == nil then return "" end
  local oct = math.floor(midi / 12) - 1
  local semitone = midi % 12
  local name = ROOT_NAMES[semitone + 1] or "?"
  return name .. tostring(oct)
end

function Scales.root_name(semitone)
  return ROOT_NAMES[(semitone % 12) + 1] or "?"
end

return Scales
