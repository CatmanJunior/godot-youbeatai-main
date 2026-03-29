class_name NotePlayerSettings
extends Resource

@export var soundfont: SoundFont
@export var notes: Notes
@export var instrument: int = 0
@export var base_note: Note
@export var allow_key_input: bool = false
@export_range(0.05, 1) var gate: float = 0.5
@export var volume_db: float = 0.0
