extends Node

@export var section_ui: Node

@export var play_pause_button: Button
@export var bpm_up_button: Button
@export var bpm_down_button: Button

# Song button
@export var song_select_button: Button

# Sample buttons
@export var instrument_buttons: Array[Sprite2D] = []

# Other interface elements
@export var corners: Array[Node2D] = []
@export var chaos_pad_triangle_sprite: Sprite2D
@export var nodes_that_can_be_unlocked: Array[Node2D] = []
@export var restart_button: Button
@export var mute_speach: CheckButton
@export var save_to_wav_button: Button
@export var cross: Node2D
@export var chosen_emoticons_label: Label
@export var metronome_toggle: CheckButton
@export var mic_meter: ProgressBar
@export var add_beats: CheckButton
@export var button_is_clap: CheckButton
@export var button_add_beats: CheckButton
@export var volume_threshold: Slider
@export var recording_delay_slider: Slider
@export var recording_delay_label: Label
@export var settings_panel: Panel
@export var settings_button: Button
@export var settings_back_button: Button
@export var skip_tutorial_button: Button
@export var progress_bar: ProgressBar
@export var pointer: Sprite2D
@export var metronome: Sprite2D
@export var metronome_bg: Sprite2D
@export var bpm_label: Label
@export var draganddropthing: Sprite2D
@export var swing_slider: Slider
@export var swing_label: Label
@export var clap_bias_slider: Slider
@export var achievements_panel: Panel
@export var section_loop_toggle: CheckButton
@export var saving_label: Label
@export var instruction_label: Label
@export var all_sections_to_mp3: Button
@export var real_time_audio_recording_progress_bar: ProgressBar
@export var activate_green_chaos_button: Sprite2D
@export var activate_purple_chaos_button: Sprite2D
@export var continue_button: Button
@export var klappy_continue: Button
@export var knob_area: Area2D
@export var amount_left: Label
@export var bear_ring_pivot_point: Node2D

# Sprite/texture management
@export var sprite_prefab: PackedScene
@export var filled_beat_textures: Array[Texture2D]
@export var outline_beat_textures: Array[Texture2D]
@export var dotted_synth_textures: Array[Texture2D]
@export var outline_synth_textures: Array[Texture2D]
@export var filled_song_texture: Texture2D
@export var outline_song_texture: Texture2D
@export var dot_beat_texture: Texture2D

var colors: PackedColorArray
var colors_override: PackedColorArray = []
var beat_sprites: Array = [] # 2D array [ring][beat]
var template_sprites: Array = [] # 2D array [ring][beat]

# State variables
var interface_set_to_default_state: bool = false
var email_prompt_open: bool = false
var dragginganddropping: bool = false
var holding_for_ring: int = 0
var progress_bar_value: float = 25.0

enum ChaosPadMode {None, SampleMixing, SynthMixing}
var chaos_pad_mode = ChaosPadMode.None

# ── Sub-manager child nodes ───────────────────────────────────────────────────
@export var beat_ring_ui: Node
@export var chaos_pad_ui: Node
@export var transport_ui: Node
@export var audio_export_ui: Node

func _ready():
	colors = %Colors.colors.duplicate()
	colors_override = colors.duplicate()

	EventBus.section_changed.connect(_on_switch_section)

	if beat_ring_ui:
		beat_ring_ui.initialize(self)
	if transport_ui:
		transport_ui.initialize(self)
	if audio_export_ui:
		audio_export_ui.initialize(self)
	if chaos_pad_ui:
		chaos_pad_ui.initialize(self)

	_init_song_select_button()

func _process(delta: float) -> void:
	update_ui(delta)

func update_ui(delta: float):
	_update_interface_state()
	_update_progress_bar()
	_update_drag_and_drop()

	if transport_ui:
		transport_ui.update(delta)
	if audio_export_ui:
		audio_export_ui.update(delta)
	if beat_ring_ui:
		beat_ring_ui.update(delta)
	if chaos_pad_ui:
		chaos_pad_ui.update(delta)
	if section_ui:
		section_ui.update(delta)

func _init_song_select_button():
	if song_select_button:
		song_select_button.button_up.connect(func():
			if section_loop_toggle:
				section_loop_toggle.button_pressed = !section_loop_toggle.button_pressed
		)

func _update_interface_state():
	if not interface_set_to_default_state:
		set_entire_interface_visibility(true)
		achievements_panel.visible = false
		interface_set_to_default_state = true

func _update_progress_bar():
	progress_bar_value = clamp(progress_bar_value, 0.0, 100.0)
	progress_bar.value = progress_bar_value

func _update_drag_and_drop():
	if dragginganddropping and holding_for_ring < colors.size():
		draganddropthing.modulate = colors[holding_for_ring]
		draganddropthing.position = get_viewport().get_mouse_position() - Vector2(1280, 720) / 2.0
	else:
		draganddropthing.modulate = Color(1, 1, 1, 0)

func set_entire_interface_visibility(visible: bool):
	if nodes_that_can_be_unlocked.size() == 0:
		return
	for node in nodes_that_can_be_unlocked:
		node.visible = visible

# Signal handlers
func _on_switch_section(_section: SectionData):
	if section_ui:
		section_ui.update_section_switch_buttons_colors()
		section_ui.set_copy_paste_clear_buttons_active(true)
	if beat_ring_ui:
		beat_ring_ui.reset_scales()

func _on_enter_pressed():
	pass
