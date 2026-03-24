extends Node
class_name SectionUI

const CLOSE_BUTTONS_HOLD_TIME: float = 3.5
const SECTION_BUTTON_SIZE: int = 72

@export var section_button_prefab: PackedScene
@export var section_buttons_container: HBoxContainer
@export var add_section_button: Button
@export var clear_section_button: Button
@export var save_section_button: Button
@export var remove_section_button: Button
@export var load_section_button: Button
@export var copy_paste_clear_buttons_holder: Control
@export var emoji_prompt: EmojiPrompt
@export var song_recording_progress_bar: ProgressBar


var section_buttons: Array[SectionButton] = []
var emoji_prompt_cancel_button: Button

var copy_paste_clear_button_holder_time_since_activation: float = 0.0

func _ready():
	print("SectionUI ready")
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_removed.connect(_on_section_removed)
	EventBus.section_switched.connect(_on_switch_section)
	EventBus.section_cleared.connect(_on_section_cleared)

	init_section_button_actions()

func _process(delta: float) -> void:
	_update_section_outline_sprite_rotation()
	_update_copy_paste_buttons(delta)


func init_section_button_actions():
	# Emoji buttons
	for button in emoji_prompt.emoji_buttons:
		button.button_up.connect(func(emoji = button.text):
			_on_emoji_button_pressed(emoji)
		)

	emoji_prompt.cancel_button.button_up.connect(_close_emoji_prompt)

	load_section_button.pressed.connect(func():
		_paste_section_button_pressed()
		_play_extra_sfx()
	)

	save_section_button.pressed.connect(func():
		_copy_section_button_pressed()
		_play_extra_sfx()
	)

	clear_section_button.pressed.connect(func():
		_clear_section_button_pressed()
		_play_extra_sfx()
	)

	add_section_button.button_up.connect(func():
		_open_emoji_prompt()
		_play_extra_sfx()
	)

	if remove_section_button:
		remove_section_button.pressed.connect(_on_remove_section_button_pressed)

func _on_remove_section_button_pressed():
	if GameState.sections.size() > 0:
		EventBus.section_removed.emit(GameState.current_section_index)
		_play_extra_sfx()

func _on_emoji_button_pressed(emoji: String):
	_close_emoji_prompt()
	EventBus.add_section_requested.emit(emoji)

func _on_section_added(new_section_index: int, emoji: String) -> void:
	print("Section added at index %d with emoji %s" % [new_section_index, emoji])
	_add_section_button(new_section_index, emoji)
	_update_section_ui()

func _on_section_removed(section_index: int) -> void:
	_remove_section_button(section_index)
	_update_section_ui()

func _on_section_cleared() -> void:
	update_section_switch_buttons_colors()

func _add_section_button(index: int, emoji: String) -> void:
	if not section_button_prefab or not section_buttons_container:
		return

	var section_button = section_button_prefab.instantiate() as SectionButton
	section_button.text = emoji if emoji != "" else ["🌱", "📜", "🤩", "🏁"][index % 4]
	section_button.pressed.connect(func():
		var section_index = section_buttons.find(section_button)
		if section_index >= 0:
			EventBus.section_switch_requested.emit(section_index)
	)

	section_buttons.insert(index, section_button)
	section_buttons_container.add_child(section_button)
	_sort_section_buttons()

func _remove_section_button(index: int) -> void:
	if index < 0 or index >= section_buttons.size():
		return

	var button_to_remove = section_buttons[index]
	section_buttons_container.remove_child(button_to_remove)
	button_to_remove.queue_free()
	section_buttons.remove_at(index)

func _sort_section_buttons() -> void:
	for i in range(section_buttons.size()):
		section_buttons_container.move_child(section_buttons[i], i)

func _update_section_ui() -> void:
	if not section_buttons_container:
		return

	section_buttons_container.size = Vector2(section_buttons.size() * SECTION_BUTTON_SIZE, SECTION_BUTTON_SIZE)
	section_buttons_container.position.x = - section_buttons_container.size.x / 2

	#TODO move to switch section function
	for button in section_buttons:
		button.outline.visible = false

	if GameState.current_section_index < section_buttons.size():
		section_buttons[GameState.current_section_index].outline.visible = true

	if song_recording_progress_bar:
		var back_panel_over_size = Vector2(16, 8)
		song_recording_progress_bar.size = section_buttons_container.size + back_panel_over_size
		song_recording_progress_bar.position = section_buttons_container.position - back_panel_over_size / 2

	update_section_switch_buttons_colors()

func _update_section_outline_sprite_rotation():
	var clock_rot = GameState.bar_progress
	section_buttons[GameState.current_section_index].rotate_outline(clock_rot * 360.0 - 7.0)

func _update_copy_paste_buttons(delta: float) -> void:
	copy_paste_clear_button_holder_time_since_activation += delta

	if copy_paste_clear_button_holder_time_since_activation >= CLOSE_BUTTONS_HOLD_TIME:
		set_copy_paste_clear_buttons_active(false)


func update_section_switch_buttons_colors() -> void:
	for i in range(section_buttons.size()):
		var button = section_buttons[i]
		button.modulate = Color(1, 1, 1, 1)

		var has_beats = GameState.sections[i].has_active_beats()
		if not has_beats:
			button.modulate = button.modulate.darkened(0.5)

func update_section_buttons_delayed() -> void:
	await get_tree().create_timer(0.2).timeout
	_update_section_ui()

func set_copy_paste_clear_buttons_active(active: bool) -> void:
	copy_paste_clear_buttons_holder.visible = active

	copy_paste_clear_button_holder_time_since_activation = 0

func _open_emoji_prompt():
	emoji_prompt.visible = true

func _close_emoji_prompt():
	emoji_prompt.visible = false

func _copy_section_button_pressed() -> void:
	EventBus.copy_requested.emit()

func _paste_section_button_pressed() -> void:
	EventBus.paste_requested.emit()

func _clear_section_button_pressed() -> void:
	EventBus.section_clear_requested.emit()

func _play_extra_sfx() -> void:
	pass

func _on_switch_section(_old_section: SectionData, _new_section: SectionData) -> void:
	_update_section_ui()
	set_copy_paste_clear_buttons_active(true)
	var i = _new_section.index
	copy_paste_clear_buttons_holder.global_position.x = section_buttons[i].global_position.x 
