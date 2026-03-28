extends SoundFontPlayer
class_name notePlayer

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
	channel_note_on(0, event.channel, event.pitch, event.velocity)


func queue_song(start: int, song: Sequence):
	note_off_all(get_time()) # clear all current notes
	# queue song
	for i in range(start, len(song.notes), 1):
		var note: SequenceNote = song.notes[i]
		var rms_value = note.velocity
		var log_value = 20.0 * (log(sqrt(rms_value) / 0.1) / log(10))

		# convert to value around 0-1
		# capped becasue soundfont does not play well with higher values
		log_value = min(1, pow(10, log_value / 10))

		# gate quiet notes
		if log_value <= gate:
			continue

		var beatDuration = (60.0 / GameState.bpm / 4.0)
		var start_time: float = float(note.beat) * beatDuration
		var stop_time: float = start_time + float(note.duration) * beatDuration
		print("%f - %f, %f" % [start_time, stop_time, beatDuration])
		channel_note_on(get_time() + start_time, 0, round(note.note), log_value)
		channel_note_off(get_time() + stop_time, 0, round(note.note))

func play_note(sequence_note: SequenceNote) -> void:
	var t = get_time()
	channel_note_on(t, 0, sequence_note.note, 1.0)
	print("playing note: %d, beat: %d, duration: %d" % [sequence_note.note, sequence_note.beat, sequence_note.duration])
	# channel_note_off(t + sequence_note.duration, 0, sequence_note.note)


func play_note_raw(note: int, duration: float) -> void:
	var t = get_time()
	channel_note_on(t, 0, note, 1.0)
	channel_note_off(t + duration, 0, note)
