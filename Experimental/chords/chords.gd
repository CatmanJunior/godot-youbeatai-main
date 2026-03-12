extends notePlayer
class_name Chords

@export var use_override = true
@export var chordString : String
@export var chordDuration: int = 4
@export var progressions: Array[ChordProgression]

@export var bpm_manager: BpmManager
@export var manager: Manager

enum ChordType {
	MAJOR,
	MINOR,
	SEVEN,
	MAJOR7,
	MINOR7
}


var chordLookup = {
	"I": 1,
	"II": 2,
	"III": 3,
	"IV": 4,
	"V": 5,
	"VI": 6,
	"VII": 7,
	"VIII": 8,
	"IX": 9,
	"X": 10
}

var song_cursor = 0
var current = 0
var chord_song = []
var layers = []

func _parse():
	if use_override: 
		return

	var chords = chordString.split("-")
	for chord in chords:
		var notationUpper = chord.to_upper()
		var note = chordLookup[notationUpper]
		var major = notationUpper == chord

		chord_song.append( func(duration): if major: on_chord_major(note, duration) else: on_chord_minor(note, duration) )


func _ready():
	super._ready()

	if not use_override: 
		load_progression()
		return


func on_bank_loaded(bank: AudioBank):
	progressions = [bank.progressions[0]]


func load_progression():
	chord_song.clear()

	for chord in progressions[0].progression:
		chord_song.append( func(duration): play_chord_object(chord, duration) )

func on_bpm():
	if len(chord_song) == 0:
		return

	current += 1
	if current % chordDuration != 0:
		return

	var beatDuration = 60.0/bpmManager.bpm /4.0
	var duration = chordDuration * beatDuration

	var current_beat = (bpm_manager.amount_of_beats * manager.currentLayerIndex) + bpm_manager.currentBeat
	song_cursor = (current_beat / chordDuration) % len(chord_song)
	chord_song[song_cursor].call(duration)


func play_chord_object(chord: Chord, duration: float):
	match chord.type:
		ChordType.MAJOR:
			on_chord_major(chord.base_note, duration)		
		ChordType.MINOR:
			on_chord_minor(chord.base_note, duration)
		ChordType.SEVEN:
			on_chord_7(chord.base_note, duration)
		ChordType.MAJOR7:
			on_chord_major_7(chord.base_note, duration)
		ChordType.MINOR7:
			on_chord_minor_7(chord.base_note, duration)


func play_chord(intervals, duration = 0.5) -> void:
	var t = get_time()
	for i in range(intervals.size()):
		channel_note_on(t, 0, base_note.id + intervals[i], 0.5)
		channel_note_off(t + duration, 0, base_note.id + intervals[i])

func on_chord_major(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset], duration)

func on_chord_minor(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 7 + offset], duration)

func on_chord_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset, 10 + offset], duration)

func on_chord_major_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset, 11 + offset], duration)

func on_chord_minor_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 7 + offset, 10 + offset], duration)

func on_chord_diminished_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 6 + offset, 9 + offset], duration)
