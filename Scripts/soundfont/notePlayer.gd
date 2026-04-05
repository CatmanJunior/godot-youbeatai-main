extends SoundFontPlayer
class_name NotePlayer

var notes: Notes
var instrument: int:
	set(v):
		instrument = v
		if is_inside_tree():
			channel_set_presetindex(0, 0, v)
var base_note: Note
var allow_key_input: bool = false
var gate: float = 0.5

func apply_settings(settings: NotePlayerSettings) -> void:
	soundfont = settings.soundfont
	notes = settings.notes
	base_note = settings.base_note
	allow_key_input = settings.allow_key_input
	gate = settings.gate
	volume_db = settings.volume_db
	instrument = settings.instrument

func _ready():
	# select instrument
	channel_set_presetindex(0, 0, instrument)

	for preset in get_presetcount():
		print("%s - %s" % [preset, get_presetname(preset)])

func _input(event):
	if event is InputEventMIDI:
		_process_midi_input(event)
		return
	if event is InputEventKey:
		_process_key_input(event)
		return

func _process_key_input(event: InputEventKey):
	if not allow_key_input:
		return
	var map = {
		KEY_A: 0,
		KEY_S: 2,
		KEY_D: 4,
		KEY_F: 5,
		KEY_G: 7,
		KEY_H: 9,
		KEY_J: 11,
		KEY_K: 12,
		KEY_L: 14,
	}

	if event.keycode not in map:
		return

	if event.is_pressed() and not event.is_echo():
		channel_note_on(0, 0, base_note.id + map[event.keycode], 1.0)
	if event.is_released():
		channel_note_off(0, 0, base_note.id + map[event.keycode])

func _process_midi_input(event: InputEventMIDI):
	channel_set_presetindex(0, event.channel, event.instrument)
	if event.message == MIDI_MESSAGE_NOTE_ON and event.velocity > 0:
		channel_note_on(0, event.channel, event.pitch, event.velocity / 127.0)
	elif event.message == MIDI_MESSAGE_NOTE_OFF or (event.message == MIDI_MESSAGE_NOTE_ON and event.velocity == 0):
		channel_note_off(0, event.channel, event.pitch)


func play_note(sequence_note: SequenceNote) -> void:
	var t = get_time()
	channel_note_on(t, 0, sequence_note.note, sequence_note.velocity)
	channel_note_off(t + gate, 0, sequence_note.note)

## Play multiple notes within a single beat, spacing them by sub_beat index.
## beat_duration is the total duration of one beat in seconds.
func play_notes(beat_notes: Array[SequenceNote], beat_duration: float) -> void:
	if beat_notes.size() == 0:
		return
	var t := get_time()
	# Find the max subdivision count among the notes to compute sub-beat spacing
	var max_sub := 1
	for sn in beat_notes:
		if sn.sub_beat + 1 > max_sub:
			max_sub = sn.sub_beat + 1
	var sub_duration := beat_duration / float(max_sub) if max_sub > 1 else beat_duration
	var note_gate := minf(gate, sub_duration)

	for sn in beat_notes:
		var offset := float(sn.sub_beat) * sub_duration
		channel_note_on(t + offset, 0, sn.note, sn.velocity)
		channel_note_off(t + offset + note_gate, 0, sn.note)


func play_note_raw(note: int, duration: float) -> void:
	var t = get_time()
	channel_note_on(t, 0, note, 1.0)
	channel_note_off(t + duration, 0, note)
