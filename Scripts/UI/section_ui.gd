extends Node

const SECTION_BUTTON_SIZE: int = 72

@export var section_manager: Node
@export var section_button_prefab: PackedScene
@export var section_buttons_container: HBoxContainer
@export var add_section_button: Button
@export var clear_section_button: Button
@export var save_section_button: Button
@export var remove_section_button: Button
@export var load_section_button: Button
@export var section_outline: Sprite2D
@export var section_outline_holder: Node2D
@export var copy_paste_clear_buttons_holder: Node2D
@export var emoji_prompt: EmojiPrompt


var section_buttons: Array[Button] = []
var emoji_prompt_cancel_button: Button

var copy_paste_clear_button_holder_time_since_activation: float = 0.0
var pressed_add_section_once: bool = false
var added_section: bool = false

var song_mode_back_panel: ProgressBar

func _ready():
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_removed.connect(_on_section_removed)
	EventBus.section_switched.connect(_on_switch_section)
	EventBus.section_cleared.connect(_on_section_cleared)

	var transport_ui = get_node_or_null("transport_ui")
	if transport_ui:
		song_mode_back_panel = transport_ui.get("real_time_audio_recording_progress_bar")

	init_section_button_actions()

	# Initialize sections & UI
	if section_manager:
		section_manager.spawn_initial_sections()

func update(delta: float):
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
		_paste_section()
		_play_extra_sfx()
	)

	save_section_button.pressed.connect(func():
		_copy_section()
		_play_extra_sfx()
	)

	clear_section_button.pressed.connect(func():
		_clear_section()
		_play_extra_sfx()
	)

	add_section_button.button_up.connect(func():
		_open_emoji_prompt()
		_play_extra_sfx()

		if not pressed_add_section_once:
			# Show tooltip
			pressed_add_section_once = true
	)

	if remove_section_button:
		remove_section_button.pressed.connect(func():
			if section_manager:
				section_manager.remove_section(section_manager.current_section_index)
		)

func _on_emoji_button_pressed(emoji: String):
	_close_emoji_prompt()
	added_section = true
	EventBus.add_section_requested.emit(emoji)

func _on_section_added(new_section_index: int, emoji: String) -> void:
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

	var section_button = section_button_prefab.instantiate() as Button
	section_button.text = emoji if emoji != "" else ["🌱", "📜", "🤩", "🏁"][index % 4]
	section_button.pressed.connect(func():
		var section_index = section_buttons.find(section_button)
		if section_manager and section_index >= 0:
			section_manager.switch_section(section_index)
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

	if section_outline_holder and section_manager and section_manager.current_section_index < section_buttons.size():
		section_outline_holder.global_position = section_buttons[section_manager.current_section_index].global_position + Vector2(SECTION_BUTTON_SIZE, SECTION_BUTTON_SIZE) / 2

	if song_mode_back_panel:
		var back_panel_over_size = Vector2(16, 8)
		song_mode_back_panel.size = section_buttons_container.size + back_panel_over_size
		song_mode_back_panel.position = section_buttons_container.position - back_panel_over_size / 2

	update_section_switch_buttons_colors()

func _update_section_outline_sprite_rotation():
	var clock_rot = GameState.bar_progress
	section_outline.rotation_degrees = clock_rot * 360.0 - 7.0

func _update_copy_paste_buttons(delta: float) -> void:
	# TODO handle showing/hiding copy/paste/clear buttons when section buttons are pressed, and hiding them after a few seconds of inactivity
	var any_section_button_pressed = false

	if copy_paste_clear_button_holder_time_since_activation >= 3.5:
		set_copy_paste_clear_buttons_active(false)
	elif not any_section_button_pressed:
		copy_paste_clear_button_holder_time_since_activation += delta

func update_section_switch_buttons_colors() -> void:
	for i in range(section_buttons.size()):
		var button = section_buttons[i]
		button.modulate = Color(1, 1, 1, 1)

		var has_beats = section_has_beats(i)
		if not has_beats:
			button.modulate = button.modulate.darkened(0.5)

func update_section_buttons_delayed() -> void:
	await get_tree().create_timer(0.2).timeout
	_update_section_ui()

func set_copy_paste_clear_buttons_active(active: bool) -> void:
	copy_paste_clear_buttons_holder.visible = active
	if active:
		copy_paste_clear_buttons_holder.position = Vector2.ZERO
	else:
		copy_paste_clear_buttons_holder.position += Vector2(0, 20000)
	copy_paste_clear_button_holder_time_since_activation = 0

func section_has_beats(section_index: int) -> bool:
	return section_manager and section_manager.section_has_beats(section_index)

func _open_emoji_prompt():
	emoji_prompt.visible = true


func _close_emoji_prompt():
	emoji_prompt.visible = false

func _copy_section() -> void:
	EventBus.copy_requested.emit()

func _paste_section() -> void:
	EventBus.paste_requested.emit()

func _clear_section() -> void:
	EventBus.section_clear_requested.emit()

func _play_extra_sfx() -> void:
	pass

func _on_switch_section(_old_section: SectionData, _new_section: SectionData) -> void:
	_update_section_ui()
	set_copy_paste_clear_buttons_active(true)
