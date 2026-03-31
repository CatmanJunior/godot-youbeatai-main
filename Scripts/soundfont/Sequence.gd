extends Node
class_name Sequence

var notes: Array[SequenceNote] = []
var _beat_map: Dictionary = {}  # beat: int → SequenceNote

func _init(sequence_notes: Array[SequenceNote]):
    notes = sequence_notes
    build_beat_map()

func build_beat_map() -> void:
    _beat_map.clear()
    for note in notes:
        _beat_map[note.beat] = note

func get_note_at_beat(beat: int) -> SequenceNote:
    return _beat_map.get(beat, null)