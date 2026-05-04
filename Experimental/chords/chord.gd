extends Resource
class_name Chord

enum ChordType {
	MAJOR,
	MINOR,
	SEVEN,
	MAJOR7,
	MINOR7
}

@export var base_note: int = 60
@export var type: ChordType = ChordType.MAJOR  # Maps to Chords.ChordType enum (MAJOR=0, MINOR=1, SEVEN=2, MAJOR7=3, MINOR7=4)