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

@export var green_soundfont: SoundFont
@export var green_instrument_id: int
@export var green_beats: float
@export var green_effectProfile: EffectProfile

@export var purple_soundfont: SoundFont
@export var purple_instrument_id: int
@export var purple_beats: float

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

var synth_soundfonts: Array[Resource] :
	get:
		return [green_soundfont, purple_soundfont]
var synth_instrument_ids: Array[int] = [green_instrument_id, purple_instrument_id]
var synth_beats: Array[float] = [green_beats, purple_beats]
var synth_effect_profiles: Array[EffectProfile] = [green_effectProfile, green_effectProfile] # default to main effect profile if synth doesn't have its own

var synth1_soundfont: Resource = null:
	get:
		return green_soundfont

var synth1_instrument_id: int = 0:
	get:
		return green_instrument_id

var synth1_beats: float = 0.0:
	get:
		return green_beats

var synth1_effectProfile: EffectProfile = null:
	get:
		return green_effectProfile

var synth2_soundfont: Resource = null:
	get:
		return purple_soundfont

var synth2_instrument_id: int = 0:
	get:
		return purple_instrument_id

var synth2_beats: float = 0.0:
	get:
		return purple_beats

var synth2_effectProfile: EffectProfile = null:
	get:
		return green_effectProfile

var effectProfile: EffectProfile = null:
	get:
		# If the synths have their own effect profile, use that. Otherwise fall back to the main one.
		return green_effectProfile
