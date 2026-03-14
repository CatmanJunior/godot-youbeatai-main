extends Node

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

var section_manager: Node

var emoji_buttons: Array = []
var emoji_prompt_cancel_button: Button

var copy_paste_clear_button_holder_time_since_activation: float = 0.0
var pressed_add_section_once: bool = false
var added_section: bool = false

func _ready():
	EventBus.section_changed.connect(_on_switch_section)
	init_section_button_actions()

func update(delta: float):
	_update_section_outline_sprite_rotation()
	_update_copy_paste_buttons(delta)

func init_section_button_actions():
	# Emoji buttons
	for button in emoji_buttons:
		button.button_up.connect(func():
			var current_section_index = section_manager.current_section_index
			add_section(current_section_index + 1, button.text)
			close_emoji_prompt()
			added_section = true
		)

	#TODO: Fix this
	# emoji_prompt_cancel_button.button_up.connect(close_emoji_prompt)

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
		open_emoji_prompt()
		_play_extra_sfx()

		if not pressed_add_section_once:
			# Show tooltip
			pressed_add_section_once = true
	)

func _update_section_outline_sprite_rotation():
	var time_per_beat = GameState.time_per_beat
	var current_beat = GameState.current_beat
	var beat_timer = GameState.beat_timer
	var beats_amount = GameState.beats_amount

	var clock_rot = 0.0
	if time_per_beat != 0:
		clock_rot = float(current_beat + (beat_timer / time_per_beat)) / float(beats_amount)
	else:
		clock_rot = float(current_beat) / float(beats_amount)

	section_outline.rotation_degrees = clock_rot * 360.0 - 7.0

func _update_copy_paste_buttons(delta: float):
	#TODO handle showing/hiding copy/paste/clear buttons when section buttons are pressed, and hiding them after a few seconds of inactivity
	var any_section_button_pressed = false

	if copy_paste_clear_button_holder_time_since_activation >= 3.5:
		set_copy_paste_clear_buttons_active(false)
	elif not any_section_button_pressed:
		copy_paste_clear_button_holder_time_since_activation += delta

func update_section_switch_buttons_colors():
	var section_buttons = []
	section_buttons = section_manager.section_buttons

	for i in range(section_buttons.size()):
		var button = section_buttons[i]

		button.modulate = Color(1, 1, 1, 1)

		var has_beats = section_has_beats(i)
		if not has_beats:
			button.modulate = button.modulate.darkened(0.5)

func update_section_buttons_delayed():
	pass

func set_copy_paste_clear_buttons_active(active: bool):
	copy_paste_clear_buttons_holder.visible = active
	if active:
		copy_paste_clear_buttons_holder.position = Vector2.ZERO
	else:
		copy_paste_clear_buttons_holder.position += Vector2(0, 20000)
	copy_paste_clear_button_holder_time_since_activation = 0

func section_has_beats(section_index: int) -> bool:
	return section_manager.section_has_beats(section_index)

func add_section(index: int, emoji: String):
	EventBus.section_added.emit(index, emoji)

func open_emoji_prompt():
	pass

func close_emoji_prompt():
	pass

func _copy_section():
	EventBus.copy_requested.emit()

func _paste_section():
	EventBus.paste_requested.emit()

func _clear_section():
	EventBus.section_clear_requested.emit()

func _play_extra_sfx():
	pass

func _on_switch_section(_old: SectionData, _section: SectionData):
	update_section_switch_buttons_colors()
	set_copy_paste_clear_buttons_active(true)
