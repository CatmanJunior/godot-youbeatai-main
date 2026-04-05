extends Node
class_name Sequence

var notes: Array[SequenceNote] = []
var _beat_map: Dictionary = {}  # beat: int → Array[SequenceNote]

func _init(sequence_notes: Array[SequenceNote]):
    notes = sequence_notes
    build_beat_map()

func build_beat_map() -> void:
    _beat_map.clear()
    for note in notes:
        if not _beat_map.has(note.beat):
            _beat_map[note.beat] = [] as Array[SequenceNote]
        _beat_map[note.beat].append(note)

## Returns the first note at the given beat (backward compatible).
func get_note_at_beat(beat: int) -> SequenceNote:
    var arr = _beat_map.get(beat, null)
    if arr and arr.size() > 0:
        return arr[0]
    return null

## Returns all notes at the given beat (up to 4 subdivisions).
func get_notes_at_beat(beat: int) -> Array[SequenceNote]:
    return _beat_map.get(beat, [] as Array[SequenceNote])