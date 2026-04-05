class_name AudioBank
extends Resource

@export var kick: AudioStream
@export var kick_alt: AudioStream

@export var snare: AudioStream
@export var snare_alt: AudioStream

@export var clap: AudioStream
@export var clap_alt: AudioStream

@export var closed: AudioStream
@export var closed_alt: AudioStream

@export var synth_soundfonts: Array[Resource]
@export var synth_instrument_ids: Array[int]
@export var synth_beats: Array[float]
@export var synth_effect_profiles: Array[EffectProfile]

@export var bpm: int = 120
@export var swing: float = 0.0

@export var noteplayer_settings: Array[NotePlayerSettings]

#THIS SHOULD BE REPLACED BY SETTING NOTEPLAYER SETTINGS IN THE AUDIO BANKS
func create_note_player_settings() -> Array[NotePlayerSettings]:
	var new_noteplayer_settings : Array[NotePlayerSettings] = []
	for i in range(noteplayer_settings.size()):
		new_noteplayer_settings.append(
		NotePlayerSettings.create(synth_soundfonts[i], noteplayer_settings[i].notes, synth_instrument_ids[i], noteplayer_settings[i].base_note, noteplayer_settings[i].allow_key_input, noteplayer_settings[i].gate, noteplayer_settings[i].volume_db),
		)
	noteplayer_settings = new_noteplayer_settings
	return new_noteplayer_settings

