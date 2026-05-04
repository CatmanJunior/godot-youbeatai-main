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
	call_deferred("_load_and_apply_bank")

func _load_and_apply_bank() -> void:
	if SongState.selected_soundbank != null:
		var bank = SongState.selected_soundbank
		fallback_bank_name = bank.resource_name
		EventBus.soundbank_loaded.emit(bank)
	else:
		push_warning("No soundbank selected, emitting fallback bank '%s'." % fallback_bank.resource_name)
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
	_create_apply_note_player_settings(bank)

	print("SoundBankLoader: loaded '%s'" % [bank_name])
	return bank

## Apply BPM and swing from the JSON dictionary.
static func _apply_bpm_swing(bank: SoundBank, bank_dict: Dictionary) -> void:
	bank.bpm = bank_dict.get("bpm", bank.bpm)
	var swing_normalized: float = float(bank_dict.get("swing", 0)) / 100.0
	bank.swing = swing_normalized


#TODO: this is a bit hacky — we have to create new NotePlayerSettings instances to apply the new AudioStreamSample references from the loaded bank, since NotePlayerSettings is a Resource and its properties are not directly editable at runtime. We should consider refactoring this in the future for better clarity and maintainability.
static func _create_apply_note_player_settings(bank: SoundBank) -> Array[NotePlayerSettings]:
	var new_noteplayer_settings : Array[NotePlayerSettings] = []
	for i in range(bank.noteplayer_settings.size()):
		new_noteplayer_settings.append(
		NotePlayerSettings.create(bank.synth_soundfonts[i], bank.noteplayer_settings[i].notes, bank.synth_instrument_ids[i], bank.noteplayer_settings[i].base_note, bank.noteplayer_settings[i].allow_key_input, bank.noteplayer_settings[i].gate, bank.noteplayer_settings[i].volume_db, bank.noteplayer_settings[i].gain),
		)
	bank.noteplayer_settings = new_noteplayer_settings
	return new_noteplayer_settings
