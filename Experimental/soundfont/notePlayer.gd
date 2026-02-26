extends SoundFontPlayer
class_name notePlayer

@export var bpmManager: BpmManager
@export var notes: Notes
@export var instrument: int :
	set(v):
		instrument = v
		channel_set_presetindex(0, 0, v)
@export var base_note : Note
@export var allow_key_input: bool = false
@export_range(0, 1, 0.05) var gate: float = 0.5

@export var songs: Array[Sequence] = []
var cached_song: Sequence = null
var current_layer: int = 0

# demo code for sub bpm detection (8th,16th notes)
#var current_beat_i : int = int(current_beat)
#var current_beat_frac : int = int((current_beat - current_beat_i) * beat_subdivision)
#$Beat.text = '%d  %d / %d' % [current_beat_i, current_beat_frac, beat_subdivision]

func _ready():
	if not bpmManager:
		bpmManager = %BPM
	
	songs.resize(11) # resize to max layers hardcoded? TODO: load max from somewhere
	# select instrument
	channel_set_presetindex(0, 0, instrument)

func set_font(font: SoundFont, instr: int):
	soundfont = font
	instrument = instr

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

	if event.keycode not in map:
		return

	if event.is_pressed() and not event.is_echo() :
		channel_note_on(0, 0, base_note.id + map[event.keycode], 1.0)
	if event.is_released():
		channel_note_off(0, 0, base_note.id + map[event.keycode])

func _process_midi_input(event: InputEventMIDI):
	channel_set_presetindex(0, event.channel, event.instrument)
	channel_note_on(0, event.channel, event.pitch, event.velocity)


func on_bpm():
	var song: Sequence = get_song()
	if song == null or len(song.sequence) == 0 or bpmManager.currentBeat >= len(song.sequence):
		return

	if bpmManager.currentBeat != 0:
		return

	# queue song
	queue_song(bpmManager.currentBeat, song)

func _on_current_layer_changed(layer: int):
	current_layer = layer

func on_layer_remove_at(layer: int) -> void:
	songs.remove_at(layer)

func on_add_layer_at(layer: int) -> void:
	songs.insert(layer, Sequence.new())

#save [copy_song] into cache
func on_song_copy(copy_song: int) -> void:
	cached_song = songs[copy_song].duplicate()

func on_paste_song(_layer: int) -> void:
	set_song(cached_song)

func on_song_clear() -> void:
	songs[current_layer].clear()

func set_song(data: Sequence) -> void:
	songs[current_layer] = data
	queue_song(bpmManager.currentBeat, data)

func get_song() -> Sequence:
	if current_layer >= len(songs):
		return null

	return songs[current_layer]

func queue_song(start: int, song: Sequence):
	note_off_all(get_time()) # clear all current notes
	# queue song
	for i in range(start, len(song.sequence), 1):
		var note: SequenceNote = song.sequence[i]
		var rms_value = note.velocity
		var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))

		# convert to value around 0-1
		# capped becasue soundfont does not play well with higher values
		log_value = min(1, pow(10, log_value / 10))

		# gate quiet notes
		if log_value <= gate:
			return

		var beatDuration = (60.0/bpmManager.bpm /4.0)
		var start_time: float = float(note.beat) * beatDuration
		var stop_time: float = start_time + float(note.duration) * beatDuration
		print("%f - %f, %f" % [start_time, stop_time, beatDuration])
		channel_note_on( get_time() + start_time, 0, round(note.note), log_value)
		channel_note_off(get_time() + stop_time, 0, round(note.note))

func play_note(note: Note, duration: float) -> void:
	var t = get_time()
	channel_note_on(t, 0, note.id, 1.0)
	channel_note_off(t + duration, 0, note.id)


func play_note_raw(note: int, duration: float) -> void:
	var t = get_time()
	channel_note_on(t, 0, note, 1.0)
	channel_note_off(t + duration, 0, note)
