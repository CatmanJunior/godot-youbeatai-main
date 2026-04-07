extends Node
class_name SoundBankLoader
## Reads SongState.selected_soundbank (set by SoundBankSelector) and
## applies the AudioBank's streams + BPM/swing to the running main scene.
##
## Add this node inside the Managers group in main.tscn.

# Path template — each soundbank folder contains an AudioBank.tres resource.
const BANK_PATH_TEMPLATE := "res://Resources/Audio/SoundBanks/%s/%s.tres"

# Fallback bank name used when nothing has been selected yet (e.g. during dev).
const FALLBACK_BANK_NAME := "2_acoustisch"

@export var fallback_bank: AudioBank

func _ready() -> void:
	if SongState.selected_soundbank == null:
		EventBus.audio_bank_loaded.emit(SongState.selected_soundbank)
	else:
		push_error("Failed to load AudioBank '%s', loading fallback bank instead." % SongState.selected_soundbank)
		EventBus.audio_bank_loaded.emit(fallback_bank)
	

static func load_audio_bank(bank_dict: Dictionary) -> AudioBank:	
	var bank : AudioBank
	# Determine which bank to load
	var bank_name: String = bank_dict.get("name", "")

	if bank_name.is_empty():
		push_warning("SoundBankLoader: no soundbank selected, falling back to '%s'." % FALLBACK_BANK_NAME)
		bank_name = FALLBACK_BANK_NAME
	
	var bank_path := BANK_PATH_TEMPLATE % [bank_name, bank_name]

	# Load the AudioBank resource
	if not ResourceLoader.exists(bank_path):
		push_error("SoundBankLoader: AudioBank not found at '%s'." % bank_path)
		return null

	bank = ResourceLoader.load(bank_path)
	if bank == null:
		push_error("SoundBankLoader: Failed to cast resource at '%s' to AudioBank." % bank_path)
		return null

	_apply_bpm_swing(bank, bank_dict)
	_create_note_player_settings(bank)

	print("SoundBankLoader: loaded '%s'" % [bank_name])
	return bank

## Apply BPM and swing from the JSON dictionary.
static func _apply_bpm_swing(bank: AudioBank, bank_dict: Dictionary) -> void:
	bank.bpm = bank_dict.get("bpm", bank.bpm)
	var swing_normalized: float = float(bank_dict.get("swing", 0)) / 100.0
	bank.swing = swing_normalized

static func _create_note_player_settings(bank: AudioBank) -> Array[NotePlayerSettings]:
	var new_noteplayer_settings : Array[NotePlayerSettings] = []
	for i in range(bank.noteplayer_settings.size()):
		new_noteplayer_settings.append(
		NotePlayerSettings.create(bank.synth_soundfonts[i], bank.noteplayer_settings[i].notes, bank.synth_instrument_ids[i], bank.noteplayer_settings[i].base_note, bank.noteplayer_settings[i].allow_key_input, bank.noteplayer_settings[i].gate, bank.noteplayer_settings[i].volume_db),
		)
	bank.noteplayer_settings = new_noteplayer_settings
	return new_noteplayer_settings

