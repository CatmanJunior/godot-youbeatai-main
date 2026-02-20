extends notePlayer
class_name Chords

@export var chordString : String
@export var chordDuration: int = 4

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

func _parse():
	var chords = chordString.split("-")
	for chord in chords:
		var notationUpper = chord.to_upper()
		var note = chordLookup[notationUpper]
		var major = notationUpper == chord
				
		chord_song.append( func(duration): if major: on_chord_major(note, duration) else: on_chord_minor(note, duration) )


func on_bpm():
	if len(chord_song) == 0:
		return
	
	current += 1
	if current % chordDuration != 0:
		return
	
	var beatDuration = 60.0/%BpmManager.bpm /4.0
	var duration = chordDuration * beatDuration
	
	chord_song[song_cursor].call(duration)
	song_cursor = (song_cursor + 1) % len(chord_song)
