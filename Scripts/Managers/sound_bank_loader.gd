extends Node
## Reads GameState.selected_soundbank (set by SoundBankSelector) and
## applies the AudioBank's streams + BPM/swing to the running main scene.
##
## Add this node inside the Managers group in main.tscn.

# Path template — each soundbank folder contains an AudioBank.tres resource.
const BANK_PATH_TEMPLATE := "res://Resources/Audio/SoundBanks/%s/%s.tres"

# Fallback bank name used when nothing has been selected yet (e.g. during dev).
const FALLBACK_BANK_NAME := "2_acoustisch"

@export var fallback_bank: AudioBank

@export var base_noteplayer_settings: Array[NotePlayerSettings]

@export var audio_player_manager: AudioPlayerManager

func _ready() -> void:
	var bank_dict: Dictionary = GameState.selected_soundbank
	var bank_name: String = bank_dict.get("name", "")
	
	var bank = load_audio_bank(bank_name)

#TODO These should all just be set in the audio bank resource, but for now we can also pull them from the JSON since that's how the UI is structured.
	_apply_soundfont_and_instrument(bank)
	_apply_bpm_swing(bank, bank_dict)
	
	EventBus.audio_bank_loaded.emit(bank)

func load_audio_bank(bank_name: String) -> AudioBank:	
	var bank : AudioBank
	# Determine which bank to load
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

	print("SoundBankLoader: loaded '%s'" % [bank_name])
	return bank

## Apply BPM and swing from the JSON dictionary.
func _apply_bpm_swing(bank: AudioBank, bank_dict: Dictionary) -> void:
	bank.bpm = bank_dict.get("bpm", bank.bpm)
	var swing_normalized: float = float(bank_dict.get("swing", 0)) / 100.0
	bank.swing = swing_normalized

func _apply_soundfont_and_instrument(bank: AudioBank) -> void:
	bank.noteplayer_settings = bank.create_note_player_settings(base_noteplayer_settings)
	print("SoundBankLoader: applied soundfont and instrument settings to AudioBank")
	print("SoundBankLoader: AudioBank noteplayer settings: %s" % bank.noteplayer_settings[0].soundfont)
