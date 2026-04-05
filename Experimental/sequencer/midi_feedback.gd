extends NotePlayer
class_name MidiFeedback

func _on_note(element: SequenceNote):
	var beatDuration = (60.0/GameState.bpm /4.0)
	var duration = float(element.duration) * beatDuration

	play_note_raw(element.note, duration)
