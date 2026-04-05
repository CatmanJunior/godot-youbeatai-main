extends Node
## Reads GameState.selected_soundbank (set by SoundBankSelector) and
## applies the AudioBank's streams + BPM/swing to the running main scene.
##
## Add this node inside the Managers group in main.tscn.

# Path template — each soundbank folder contains an AudioBank.tres resource.
const BANK_PATH_TEMPLATE := "res://Resources/Audio/SoundBanks/%s/AudioBank.tres"

# Fallback bank name used when nothing has been selected yet (e.g. during dev).
const FALLBACK_BANK_NAME := "2_acoustisch"

@export var fallback_bank: AudioBank

@export var base_noteplayer_settings: Array[NotePlayerSettings]

@export var audio_player_manager: AudioPlayerManager

func _ready() -> void:
	var bank_dict: Dictionary = GameState.selected_soundbank
	var bank : AudioBank
	# Determine which bank to load
	var bank_name: String = bank_dict.get("name", "")
	if bank_name.is_empty():
		push_warning("SoundBankLoader: no soundbank selected, falling back to '%s'." % FALLBACK_BANK_NAME)
		bank_name = FALLBACK_BANK_NAME
		bank = fallback_bank
	else:
		var bank_path := BANK_PATH_TEMPLATE % bank_name

		# Load the AudioBank resource
		if not ResourceLoader.exists(bank_path):
			push_error("SoundBankLoader: AudioBank not found at '%s'." % bank_path)
			return

		bank = ResourceLoader.load(bank_path)
		if bank == null:
			push_error("SoundBankLoader: Failed to cast resource at '%s' to AudioBank." % bank_path)
			return

	_apply_streams(bank)
	_apply_bpm_swing(bank_dict)
	_apply_effect_profile(bank)
	_apply_soundfont_and_instrument(bank)

	EventBus.soundbank_loaded.emit(bank_name)


	print("SoundBankLoader: loaded '%s' (bpm=%d, swing=%d%%)" % [
		bank_name,
		bank_dict.get("bpm", 0),
		bank_dict.get("swing", 0)
	])


## Push the AudioBank's audio files into AudioPlayerManager via EventBus.
## Track layout:  0=kick  1=clap  2=snare  3=closed  (matches main.tscn export order)
func _apply_streams(bank: AudioBank) -> void:
	# Main (dry) streams
	EventBus.set_stream_requested.emit(0, 0, bank.kick)
	EventBus.set_stream_requested.emit(1, 0, bank.clap)
	EventBus.set_stream_requested.emit(2, 0, bank.snare)
	EventBus.set_stream_requested.emit(3, 0, bank.closed)

	# Alt streams (layer 1)
	EventBus.set_stream_requested.emit(0, 1, bank.kick_alt)
	EventBus.set_stream_requested.emit(1, 1, bank.clap_alt)
	EventBus.set_stream_requested.emit(2, 1, bank.snare_alt)
	EventBus.set_stream_requested.emit(3, 1, bank.closed_alt)


## Apply BPM and swing from the JSON dictionary.
func _apply_bpm_swing(bank_dict: Dictionary) -> void:
	var bpm: int = bank_dict.get("bpm", 120)
	var swing_pct: int = bank_dict.get("swing", 0)

	EventBus.bpm_set_requested.emit(bpm)

	# Swing is stored as a percentage (0–100) in the JSON.
	# BpmManager expects a normalised float (0.0–1.0).
	var swing_normalized: float = float(swing_pct) / 100.0
	EventBus.swing_set_requested.emit(swing_normalized)


## Apply the AudioBank's effect profile to the mixer buses.
func _apply_effect_profile(bank: AudioBank) -> void:
	if bank.effectProfile == null:
		return
	audio_player_manager.track_players[4].apply_effect_profile(bank.effectProfile)
	audio_player_manager.track_players[5].apply_effect_profile(bank.effectProfile)

func _apply_soundfont_and_instrument(bank: AudioBank) -> void:
	
	var new_noteplayer_settings : Array[NotePlayerSettings]= [
		NotePlayerSettings.create(bank.synth1_soundfont, base_noteplayer_settings[0].notes, bank.synth1_instrument_id, base_noteplayer_settings[0].base_note, base_noteplayer_settings[0].allow_key_input, base_noteplayer_settings[0].gate, base_noteplayer_settings[0].volume_db),
		NotePlayerSettings.create(bank.synth2_soundfont, base_noteplayer_settings[1].notes, bank.synth2_instrument_id, base_noteplayer_settings[1].base_note, base_noteplayer_settings[1].allow_key_input, base_noteplayer_settings[1].gate, base_noteplayer_settings[1].volume_db)
	]
	
	print("Applying soundfont and instrument settings for synth tracks:")
	for i in range(2):
		print("  Synth Track %d: soundfont=%s, instrument_id=%d" % [
			i+1,
			str(new_noteplayer_settings[i].soundfont),
			new_noteplayer_settings[i].instrument
		])
	EventBus.note_player_settings_changed.emit(new_noteplayer_settings)
