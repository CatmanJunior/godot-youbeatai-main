extends Node
class_name SoundBankLoader
## Reads SongState.selected_soundbank (set by SoundBankSelector) and
## applies the SoundBank's streams + BPM/swing to the running main scene.
##
## Add this node inside the Managers group in main.tscn.

# Path template — each soundbank folder contains a SoundBank.tres resource.
const BANK_PATH_TEMPLATE := "res://Resources/Audio/SoundBanks/%s/%s.tres"

static var fallback_bank_name: String = ""

@export var fallback_bank: SoundBank

func _ready() -> void:
	# Defer loading the bank until the main scene is fully initialized, to ensure SongState and EventBus are ready to receive the loaded data.
	EventBus.players_initialized.connect(_load_and_apply_bank)

func _load_and_apply_bank() -> void:
	if SongState.selected_soundbank != null:
		var bank = SongState.selected_soundbank
		fallback_bank_name = bank.resource_name
		EventBus.soundbank_loaded.emit(bank)
	else:
		push_warning("No soundbank selected, emitting fallback bank '%s'." % fallback_bank.resource_path.split("/")[-1])
		fallback_bank_name = fallback_bank.resource_name
		EventBus.soundbank_loaded.emit(fallback_bank)


static func load_soundbank(bank_dict: Dictionary) -> SoundBank:	
	var bank : SoundBank
	print("SoundBankLoader: loading soundbank with data: %s" % [bank_dict])
	# Determine which bank to load
	var bank_name: String = bank_dict.get("name", "")


	if bank_name.is_empty():
		bank_name = fallback_bank_name
		push_warning("SoundBankLoader: no soundbank selected, falling back to '%s'." % bank_name)
	
	var bank_path := BANK_PATH_TEMPLATE % [bank_name, bank_name]

	# Load the SoundBank resource
	if not ResourceLoader.exists(bank_path):
		push_error("SoundBankLoader: SoundBank not found at '%s'." % bank_path)
		return null

	bank = ResourceLoader.load(bank_path)
	if bank == null:
		push_error("SoundBankLoader: Failed to cast resource at '%s' to SoundBank." % bank_path)
		return null

	_apply_bpm_swing(bank, bank_dict)
	_patch_note_player_settings(bank)

	print("SoundBankLoader: loaded '%s'" % [bank_name])
	return bank

## Apply BPM and swing from the JSON dictionary.
static func _apply_bpm_swing(bank: SoundBank, bank_dict: Dictionary) -> void:
	bank.bpm = bank_dict.get("bpm", bank.bpm)
	var swing_normalized: float = float(bank_dict.get("swing", 0)) / 100.0
	bank.swing = swing_normalized


## Duplicates each NotePlayerSettings from the cached resource and injects the
## bank-specific soundfont and instrument, without mutating the cached originals.
static func _patch_note_player_settings(bank: SoundBank) -> void:
	for i in range(bank.noteplayer_settings.size()):
		var settings: NotePlayerSettings = bank.noteplayer_settings[i].duplicate()
		settings.soundfont = bank.synth_soundfonts[i]
		settings.instrument = bank.synth_instrument_ids[i]
		bank.noteplayer_settings[i] = settings
