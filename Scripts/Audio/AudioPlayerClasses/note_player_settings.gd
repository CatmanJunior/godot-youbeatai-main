class_name NotePlayerSettings
extends Resource

@export var soundfont: SoundFont
@export var notes: Notes
@export var instrument: int = 0
@export var base_note: Note
@export var allow_key_input: bool = false
@export_range(0.05, 1) var gate: float = 0.5
@export var volume_db: float = 0.0

@warning_ignore("shadowed_variable")
func _init(soundfont: SoundFont, notes: Notes, instrument: int, base_note: Note, allow_key_input: bool, gate: float, volume_db: float) -> void:
    self.soundfont = soundfont
    self.notes = notes
    self.instrument = instrument
    self.base_note = base_note
    self.allow_key_input = allow_key_input
    self.gate = gate
    self.volume_db = volume_db

    