extends Node

## Visibility manager for controlling UI element visibility.
## Uses a helper to eliminate repetitive null-check + set-visible boilerplate.

# State
var interface_set_to_default_state: bool = false

# Reference to UI Manager
var ui: Node

# Beat sprites (2D arrays - populated at runtime)
var beat_sprites: Array = [] # [ring][beat]
var template_sprites: Array = [] # [ring][beat]


func _ready():
	ui = get_node("%UiManager")


## Helper: safely set .visible on a node, handling nulls and chained access.
## Accepts a Callable that returns the target node, catching nulls gracefully.
static func _set_visible_safe(node: Node, value: bool) -> void:
	if node != null:
		node.visible = value


## Batch-set visibility on an array of nullable nodes.
func _set_visible_batch(nodes: Array, value: bool) -> void:
	for node in nodes:
		_set_visible_safe(node, value)


func set_entire_interface_visibility(visible: bool) -> void:
	if not ui:
		return

	for ring in range(4):
		set_ring_visibility(ring, visible)

	# Transport UI elements
	var transport := ui.transport_ui if ui.get("transport_ui") else null
	if transport:
		_set_visible_batch([
			transport.get("play_pause_button"),
			transport.get("bpm_label"),
			transport.get("metronome"),
			transport.get("metronome_bg"),
			transport.get("progress_bar"),
		], visible)

	# Settings UI elements
	var settings := ui.settings_ui if ui.get("settings_ui") else null
	if settings:
		_set_visible_batch([
			settings.get("settings_button"),
			settings.get("mute_speach"),
		], visible)

	# Chaos pad elements
	var chaos := ui.chaos_pad_ui if ui.get("chaos_pad_ui") else null
	if chaos:
		_set_visible_batch([
			chaos.get("activate_green_chaos_button"),
			chaos.get("activate_purple_chaos_button"),
		], visible)

	# Top-level UI elements
	_set_visible_batch([
		ui.get("layer_loop_toggle"),
		ui.get("cross"),
		ui.get("chosen_emoticons_label"),
		ui.get("achievements_panel"),
		ui.get("layer_buttons_container"),
	], visible)

	set_main_buttons_visibility(visible)
	set_recording_buttons_visibility(visible)
	set_drag_and_drop_buttons_visibility(visible)


func set_ring_visibility(ring: int, visible: bool) -> void:
	if ring < 0 or ring >= beat_sprites.size():
		return

	for beat in range(beat_sprites[ring].size()):
		_set_visible_safe(beat_sprites[ring][beat], visible)

	if ring < template_sprites.size():
		for beat in range(template_sprites[ring].size()):
			_set_visible_safe(template_sprites[ring][beat], visible)


func set_main_buttons_visibility(visible: bool) -> void:
	if not ui:
		return
	_set_visible_batch([
		ui.get("save_layout_button"),
		ui.get("load_layout_button"),
		ui.get("clear_layout_button"),
	], visible)


func set_bpm_controls_visibility(visible: bool) -> void:
	if not ui:
		return

	var transport := ui.transport_ui if ui.get("transport_ui") else null
	if transport:
		_set_visible_batch([
			transport.get("bpm_up_button"),
			transport.get("bpm_down_button"),
			transport.get("bpm_label"),
			transport.get("swing_slider"),
			transport.get("swing_label"),
			transport.get("metronome"),
			transport.get("metronome_bg"),
		], visible)


func set_recording_buttons_visibility(visible: bool) -> void:
	if not ui:
		return
	_set_visible_batch([
		ui.get("record_sample_button0"),
		ui.get("record_sample_button1"),
		ui.get("record_sample_button2"),
		ui.get("record_sample_button3"),
	], visible)


func set_drag_and_drop_buttons_visibility(visible: bool) -> void:
	if not ui:
		return
	_set_visible_batch([
		ui.get("draganddrop_button0"),
		ui.get("draganddrop_button1"),
		ui.get("draganddrop_button2"),
		ui.get("draganddrop_button3"),
	], visible)


func set_green_layer_visibility(visible: bool) -> void:
	if not ui:
		return
	_set_visible_safe(ui.get("activate_green_chaos_button"), visible)


func set_purple_layer_visibility(visible: bool) -> void:
	if not ui or not ui.chaos_pad_ui:
		return
	_set_visible_safe(ui.chaos_pad_ui.get("activate_purple_chaos_button"), visible)


func set_mic_recorder_visibility(visible: bool) -> void:
	pass # implemented via specific scene connections


func set_layer_switch_buttons_visibility(visible: bool) -> void:
	if not ui:
		return
	_set_visible_safe(ui.get("layer_buttons_container"), visible)


func hide_all() -> void:
	set_entire_interface_visibility(false)


func show_all() -> void:
	set_entire_interface_visibility(true)
