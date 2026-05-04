class_name NotePlayerSettings
extends Resource

@export var soundfont: SoundFont
@export var notes: Notes
@export var instrument: int = 0
@export var base_note: Note
@export var allow_key_input: bool = false
@export_range(0.05, 1) var gate: float = 0.5
@export var volume_db: float = 0.0
@export var gain: float = 0.0

@warning_ignore("shadowed_variable")
static func create(soundfont: SoundFont, notes: Notes, instrument: int, base_note: Note, allow_key_input: bool, gate: float, volume_db: float, gain: float) -> NotePlayerSettings:
	var instance = NotePlayerSettings.new()
	instance.soundfont = soundfont
	instance.notes = notes
	instance.instrument = instrument
	instance.base_note = base_note
	instance.allow_key_input = allow_key_input
	instance.gate = gate
	instance.volume_db = volume_db
	instance.gain = gain
	return instance