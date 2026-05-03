extends Node
class_name SoundBankSelector


var chosen_electronic_factor_themes: int = -1
var offset_lookup: Dictionary = {}
var lookup: Dictionary = {}
var soundbanks: Array = []

var chosen_soundbank: Dictionary = {}

@export var soundbank_selection_menu: SoundBankSelectionMenu

func _ready() -> void:
	offset_lookup = _load_json("res://Resources/SoundBankMatrix/bpmoffset.json")
	lookup = _load_json("res://Resources/SoundBankMatrix/elec.json")
	soundbanks = load_soundbanks()

	EventBus.soundbank_selected.connect(_on_soundbank_selected)

func _on_soundbank_selected(themes: Array[String], emotions: Array[String]) -> void:
	var chosen_bank : Dictionary = choose_soundbank(themes, emotions)
	SongState.selected_soundbank = SoundBankLoader.load_soundbank(chosen_bank)
	

func _process(_delta: float) -> void:
	if soundbank_selection_menu.check_ready_condition():
		update_soundbank_label(soundbank_selection_menu.chosen_themes_emojis, soundbank_selection_menu.chosen_emotions_emojis)

func _load_json(res_path: String) -> Variant:
	var file := FileAccess.open(res_path, FileAccess.READ)
	if file == null:
		push_error("Could not open: " + res_path)
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("JSON parse error in " + res_path + ": " + json.get_error_message())
		return {}
	return json.data


func update_soundbank_label(chosen_themes: Array[String], chosen_emotions: Array[String]) -> void:
	chosen_soundbank = choose_soundbank(chosen_themes, chosen_emotions)
	soundbank_selection_menu.gevonden_soundbank_label.text = generate_soundbank_label(chosen_themes)


func _get_offset(chosen_themes: Array[String]) -> int:
	var offset := 0
	for t in chosen_themes:
		if offset_lookup.has(t):
			offset += int(offset_lookup[t])
	return offset


func get_electronic_label(chosen_themes: Array[String]) -> String:
	var a := 0
	var b := 0
	var c := 0

	if chosen_themes.size() > 0:
		for t in chosen_themes:
			var e := int(lookup[t])
			if e == 0:
				a += 1
			if e == 1:
				b += 1
			if e == 2:
				c += 1

	var elec_str := "none"
	if a > 0 or b > 0 or c > 0:
		var largest_value := maxi(a, maxi(b, c))
		if largest_value == a:
			chosen_electronic_factor_themes = 0
		if largest_value == b:
			chosen_electronic_factor_themes = 1
		if largest_value == c:
			chosen_electronic_factor_themes = 2
		if chosen_electronic_factor_themes == 0:
			elec_str = "accoustisch"
		if chosen_electronic_factor_themes == 1:
			elec_str = "normaal"
		if chosen_electronic_factor_themes == 2:
			elec_str = "electrisch"

	return elec_str


func generate_soundbank_label(chosen_themes: Array[String]) -> String:
	if chosen_soundbank.is_empty():
		return "..."

	var elec_str := get_electronic_label(chosen_themes)
	return (
		str(chosen_soundbank.get("name", ""))
		+" (bpm: " + str(chosen_soundbank.get("bpm", 0))
		+", swing: " + str(chosen_soundbank.get("swing", 0))
		+"%, bpm-offset: " + str(_get_offset(chosen_themes))
		+") (" + elec_str + ")"
	)


func choose_soundbank(chosen_themes: Array[String], chosen_emotions: Array[String]) -> Dictionary:
	var best_match: Dictionary = {}
	var best_score: float = -INF

	for bank in soundbanks:		
		var theme_matches := 0
		var bank_themes = bank.get("themes", [])
		for theme in chosen_themes:
			if bank_themes.has(theme):
				theme_matches += 1

		var emotion_matches := 0
		var bank_emoij = bank.get("emotions", [])

		for emotion in chosen_emotions:
			if bank_emoij.has(emotion):
				emotion_matches += 1

		if theme_matches == 0 and emotion_matches == 0:
			continue

		var theme_score: float = float(theme_matches) / float(chosen_themes.size()) if chosen_themes.size() > 0 else 0.0
		var emotion_score: float = float(emotion_matches) / float(chosen_emotions.size()) if chosen_emotions.size() > 0 else 0.0

		var total_score: float = (theme_score * 0.5) + (emotion_score * 0.3)

		if best_score == total_score:
			if chosen_electronic_factor_themes == bank.get("electronic", -1):
				total_score += 0.01
			else:
				total_score -= 0.01

		if total_score > best_score:
			best_score = total_score
			best_match = bank

	return best_match


func load_soundbanks() -> Array:
	var path := "res://Resources/SoundBankMatrix/soundbanks.json"
	if not FileAccess.file_exists(path):
		push_error("json file not found")
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("Failed to parse soundbanks.json: " + json.get_error_message())
		return []

	return json.data
