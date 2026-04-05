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
func create_note_player_settings(note_player_settings: Array[NotePlayerSettings]) -> Array[NotePlayerSettings]:
	var new_noteplayer_settings : Array[NotePlayerSettings] = []
	for i in range(note_player_settings.size()):
		new_noteplayer_settings.append(
		NotePlayerSettings.create(synth_soundfonts[i], note_player_settings[i].notes, synth_instrument_ids[i], note_player_settings[i].base_note, note_player_settings[i].allow_key_input, note_player_settings[i].gate, note_player_settings[i].volume_db),
		)
	return new_noteplayer_settings

var synth1_soundfont: Resource = null:
	get:
		return synth_soundfonts[0] if synth_soundfonts.size() > 0 else null

var synth1_instrument_id: int = 0:
	get:
		return synth_instrument_ids[0] if synth_instrument_ids.size() > 0 else 0

var synth1_beats: float = 0.0:
	get:
		return synth_beats[0] if synth_beats.size() > 0 else 0.0

var synth1_effectProfile: EffectProfile = null:
	get:
		return synth_effect_profiles[0] if synth_effect_profiles.size() > 0 else null

var synth2_soundfont: Resource = null:
	get:
		return synth_soundfonts[1] if synth_soundfonts.size() > 1 else null

var synth2_instrument_id: int = 0:
	get:
		return synth_instrument_ids[1] if synth_instrument_ids.size() > 1 else 0

var synth2_beats: float = 0.0:
	get:
		return synth_beats[1] if synth_beats.size() > 1 else 0.0

var synth2_effectProfile: EffectProfile = null:
	get:
		return synth_effect_profiles[1] if synth_effect_profiles.size() > 1 else null

var effectProfile: EffectProfile = null:
	get:
		return synth_effect_profiles[0] if synth_effect_profiles.size() > 0 else null
