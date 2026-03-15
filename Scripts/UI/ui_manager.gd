extends Node

@export var section_ui: Node

# Song button
@export var song_select_button: Button

# Other interface elements

@export var nodes_that_can_be_unlocked: Array[Node2D] = []
@export var cross: Node2D
@export var chosen_emoticons_label: Label

@export var instruction_panel: Panel


var colors: PackedColorArray = []
var colors_override: PackedColorArray = []

# State variables
var interface_set_to_default_state: bool = false
var email_prompt_open: bool = false
var dragginganddropping: bool = false
var holding_for_ring: int = 0

# ── Sub-manager child nodes ───────────────────────────────────────────────────
@export var beat_ring_ui: Node
@export var chaos_pad_ui: Node
@export var transport_ui: Node
@export var settings_ui: Node

func _ready():
	colors = %Colors.colors.duplicate()
	colors_override = colors.duplicate()

	EventBus.section_switched.connect(_on_switch_section)

	beat_ring_ui.initialize()

	
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

# Signal handlers
func _on_switch_section(_old_section: SectionData, _new_section: SectionData):
	# if section_ui:
	# 	section_ui.update_section_switch_buttons_colors()
	# 	section_ui.set_copy_paste_clear_buttons_active(true)
	if beat_ring_ui:
		beat_ring_ui.reset_scales()
