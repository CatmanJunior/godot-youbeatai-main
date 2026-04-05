extends Panel
class_name SoundBankSelectionMenu

var amount_emotions_selected: int = 0
var amount_themes_selected: int = 0

var chosen_emotions_emojis: Array[String] = []
var chosen_themes_emojis: Array[String] = []

@export var emotion_toggles: DualSelectButtonGroup
@export var theme_toggles: DualSelectButtonGroup

@export var selected_emotion_labels: Array[Label]
@export var selected_theme_labels: Array[Label]

@export var gebruik_button: Button
@export var gevonden_soundbank_label: Label

@export var beatSelectButtonGroup: ButtonGroup

func _ready() -> void:
	if GameState.tutorialActivated:
		selected_emotion_labels[0].text = "😁"
		selected_theme_labels[0].text = "💔"
		chosen_emotions_emojis.append("😁")
		chosen_themes_emojis.append("💔")

	beatSelectButtonGroup.pressed.connect(_on_beat_button_group_pressed)
	emotion_toggles.pressed.connect(_on_emotion_toggle)
	theme_toggles.pressed.connect(_on_theme_toggle)
	gebruik_button.pressed.connect(_on_gebruik_pressed)

func _on_beat_button_group_pressed(button: BaseButton) -> void:
	var beats := 0
	#button name is button_8, button_16 or button_32, extract the number
	var parts := button.name.split("_")
	if parts.size() == 2:
		beats = int(parts[1])
	_set_beats(beats)

func _on_emotion_toggle(buttons: Array[BaseButton]) -> void:
	amount_emotions_selected = buttons.size()
	chosen_emotions_emojis.clear()
	for btn in buttons:
		chosen_emotions_emojis.append(get_label_text(btn))
	for i in chosen_emotions_emojis.size():
		selected_emotion_labels[i].text = chosen_emotions_emojis[i]
		
	check_ready_condition()

func _on_theme_toggle(buttons: Array[BaseButton]) -> void:
	amount_themes_selected = buttons.size()
	chosen_themes_emojis.clear()
	for btn in buttons:
		chosen_themes_emojis.append(get_label_text(btn))
	for i in chosen_themes_emojis.size():
		selected_theme_labels[i].text = chosen_themes_emojis[i]
	check_ready_condition()

func check_ready_condition() -> bool:
	if amount_emotions_selected == 2 and amount_themes_selected == 2:
		gebruik_button.disabled = false
		return false
	else:
		gebruik_button.disabled = true
		return true
	
func get_label_text(button: BaseButton) -> String:
	var label = button.get_child(0) as Label
	return label.text
	
func _on_gebruik_pressed() -> void:
	end_soundbank_selection()

func end_soundbank_selection() -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	
	EventBus.audio_bank_selected.emit(chosen_emotions_emojis, chosen_themes_emojis)
	await get_tree().create_timer(0.5).timeout
	change_to_main()
	
func change_to_main() -> void:
	SceneChanger.go_to_main()
	
func _set_beats(beats: int) -> void:
	GameState.total_beats = beats

func _on_soundbank_label_changed(label_text: String) -> void:
	gevonden_soundbank_label.text = label_text
