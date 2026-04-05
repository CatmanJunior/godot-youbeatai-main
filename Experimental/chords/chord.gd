extends Resource
class_name Chord

@export var base_note: int
@export var type: int = 0  # Maps to Chords.ChordType enum (MAJOR=0, MINOR=1, SEVEN=2, MAJOR7=3, MINOR7=4)