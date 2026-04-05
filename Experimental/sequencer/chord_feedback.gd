extends NotePlayer
class_name  ChordFeedback

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

func _on_note(note: SequenceNote):
	var notationUpper = note.chord.to_upper()
	var note_in_scale = chordLookup[notationUpper]
	var major = notationUpper == note.chord

	if major:
		on_chord_major(note_in_scale, note.duration)
	else:
		on_chord_minor(note_in_scale, note.duration)


func play_chord(intervals, duration = 0.5) -> void:
	var t = get_time()
	for i in intervals:
		channel_note_on(t, 0, base_note.id + i, 1.0)
		channel_note_off(t + duration, 0, base_note.id + i)

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
