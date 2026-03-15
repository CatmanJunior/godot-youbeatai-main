extends Node

@export var section_ui: Node

# Song button
@export var song_select_button: Button

# Other interface elements

@export var nodes_that_can_be_unlocked: Array[Node2D] = []
@export var cross: Node2D
@export var chosen_emoticons_label: Label

@export var instruction_panel: Panel

# State variables
var interface_set_to_default_state: bool = false
var email_prompt_open: bool = false
var dragginganddropping: bool = false
var holding_for_ring: int = 0

# ── Sub-manager child nodes ───────────────────────────────────────────────────
@export var beat_ring_ui: BeatRingUI
@export var chaos_pad_ui: ChaosPadUI
@export var transport_ui: TransportUI
@export var settings_ui: SettingsUI

func _ready():
	_init_song_select_button()

func _process(delta: float) -> void:
	update_ui(delta)

func update_ui(delta: float):
	_update_interface_state()

	transport_ui.update(delta)

	beat_ring_ui.update(delta)

	section_ui.update(delta)

func _init_song_select_button():
	if song_select_button:
		song_select_button.button_up.connect(func():
			if transport_ui and transport_ui.section_loop_toggle:
				transport_ui.section_loop_toggle.button_pressed = !transport_ui.section_loop_toggle.button_pressed
		)

func _update_interface_state():
	if not interface_set_to_default_state:
		set_entire_interface_visibility(true)
		if instruction_panel:
			instruction_panel.visible = false
		interface_set_to_default_state = true

func set_entire_interface_visibility(visible: bool):
	if nodes_that_can_be_unlocked.size() == 0:
		return
	for node in nodes_that_can_be_unlocked:
		node.visible = visible


		
