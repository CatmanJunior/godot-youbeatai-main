extends SoundFontPlayer
class_name notePlayer

@export var bpmManager: Node
@export var notes: Notes
@export var instrument: int
@export var base_note : Note

@export var song: PackedVector3Array = []
@export var progress: int = 0

func _ready():
	# select instrument
	channel_set_presetindex(0, 0, instrument)

func _input(event):
	if event is InputEventMIDI:
		_process_midi_input(event)
		return
	
	if event is InputEventKey:
		_process_key_input(event)
		return

func _process_key_input(event: InputEventKey):
	var map = {
		KEY_A:0,
		KEY_S:2,
		KEY_D:4,
		KEY_F:5,
		KEY_G:7,
		KEY_H:9,
		KEY_J:11,
		KEY_K:12,
		KEY_L:14,
	}
	
	if event.is_pressed():
		channel_note_on(0, 0, base_note.id + map[event.keycode], 1.0)
	if event.is_released():
		channel_note_off(0, 0, base_note.id + map[event.keycode])

func _process_midi_input(event: InputEventMIDI):
	channel_set_presetindex(0, event.channel, event.instrument)
	channel_note_on(0, event.channel, event.pitch, event.velocity)

func on_bpm():
	if len(song) == 0:
		return
	
	var rms_value = song[bpmManager.currentBeat].y
	var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))
	channel_note_on(0, 0, song[bpmManager.currentBeat].x, log_value)

func on_playing_changed(state: bool):
	pass
	
func set_song(data: Array[Note]):
	song = data
	
func play_note(note: Note, duration: float):
	var t = get_time()
	channel_note_on(t, 0, note.id, 1.0)
	channel_note_off(t + duration, 0, note.id)
	
func play_chord(base_note: int, intervals):
	var duration : float = 0.5
	var t = get_time()
	for i in intervals:
		channel_note_on(t, 0, base_note + i, 1.0)
		channel_note_off(t + duration, 0, base_note + i)

func on_chord_major():
	play_chord(base_note.id, [0, 4, 7])

func on_chord_minor():
	play_chord(base_note.id, [0, 3, 7])

func on_chord_7():
	play_chord(base_note.id, [0, 4, 7, 10])

func on_chord_major_7():
	play_chord(base_note.id, [0, 4, 7, 11])

func on_chord_minor_7():
	play_chord(base_note.id, [0, 3, 7, 10])

func on_chord_diminished_7():
	play_chord(base_note.id, [0, 3, 6, 9])
