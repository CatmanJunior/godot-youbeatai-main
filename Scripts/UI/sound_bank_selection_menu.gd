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

@export var start_button: Button
@export var current_soundbank_label: Label

@export var beatSelectButtonGroup: ButtonGroup

@export var emotion_placeholders: Array[Sprite2D]
@export var theme_placeholders: Array[Sprite2D]

var _update := false

func _ready() -> void:
	if not OS.is_debug_build():
		current_soundbank_label.visible = false

	if GameState.use_tutorial:
		#set 2 random emotions and themes for the tutorial that are pre-pressed
		emotion_toggles.set_pressed_buttons([emotion_toggles._buttons[0]])
		theme_toggles.set_pressed_buttons([theme_toggles._buttons[0]])
		_on_emotion_toggle(emotion_toggles.get_pressed_buttons())
		_on_theme_toggle(theme_toggles.get_pressed_buttons())		

	beatSelectButtonGroup.pressed.connect(_on_beat_button_group_pressed)
	emotion_toggles.pressed.connect(_on_emotion_toggle)
	theme_toggles.pressed.connect(_on_theme_toggle)
	start_button.pressed.connect(_on_gebruik_pressed)

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

	for i in range(selected_emotion_labels.size()):
		selected_emotion_labels[i].text = ""
		emotion_placeholders[i].visible = true

	for i in range(buttons.size()):
		var emoji = get_label_text(buttons[i])
		chosen_emotions_emojis.append(emoji)

		selected_emotion_labels[i].text = emoji
		emotion_placeholders[i].visible = false

	_update = true
	update_button_state()

func _on_theme_toggle(buttons: Array[BaseButton]) -> void:
	amount_themes_selected = buttons.size()
	chosen_themes_emojis.clear()

	for i in range(selected_theme_labels.size()):
		selected_theme_labels[i].text = ""
		theme_placeholders[i].visible = true

	for i in range(buttons.size()):
		var emoji = get_label_text(buttons[i])
		chosen_themes_emojis.append(emoji)

		selected_theme_labels[i].text = emoji
		theme_placeholders[i].visible = false

	_update = true
	update_button_state()

func update_button_state():
	if amount_emotions_selected == 2 and amount_themes_selected == 2:
		start_button.disabled = false
	else:
		start_button.disabled = true


func check_ready_condition() -> bool:
	var last_update = _update
	_update = false # reset
	return last_update
	
func get_label_text(button: BaseButton) -> String:
	var label = button.get_child(0) as Label
	return label.text
	
func _on_gebruik_pressed() -> void:
	end_soundbank_selection()

func end_soundbank_selection() -> void:
	TTSHelper.stop_speaking()
	
	EventBus.soundbank_selected.emit(chosen_themes_emojis, chosen_emotions_emojis)
	await get_tree().create_timer(0.5).timeout
	change_to_main()
	
func change_to_main() -> void:
	SceneChanger.go_to_main()
	
func _set_beats(beats: int) -> void:
	SongState.beats_per_section = beats

func set_current_soundbank_label(soundfont_name: String) -> void:
	current_soundbank_label.text = "DEBUG ONLY - Gevonden Soundbank: " + soundfont_name
