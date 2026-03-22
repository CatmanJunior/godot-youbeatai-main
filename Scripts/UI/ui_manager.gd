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




# ── Sub-manager child nodes ───────────────────────────────────────────────────

@export var chaos_pad_ui: ChaosPadUI
@export var transport_ui: TransportUI
@export var settings_ui: SettingsUI





func set_entire_interface_visibility(visible: bool):
	if nodes_that_can_be_unlocked.size() == 0:
		return
	for node in nodes_that_can_be_unlocked:
		node.visible = visible


		
