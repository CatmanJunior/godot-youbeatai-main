extends Node

# Visibility manager for controlling UI element visibility

# State
var interface_set_to_default_state: bool = false

# Reference to UI Manager
var ui: Node

# Beat sprites (2D arrays - would need to be populated)
var beat_sprites: Array = [] # [ring][beat]
var template_sprites: Array = [] # [ring][beat]

func _ready():
	ui = get_node("%UiManager")

func set_entire_interface_visibility(visible: bool):
	"""Set visibility of all interface elements"""
	if not ui:
		return
	
	set_ring_visibility(0, visible)
	set_ring_visibility(1, visible)
	set_ring_visibility(2, visible)
	set_ring_visibility(3, visible)
	
	if ui.transport_ui and ui.transport_ui.play_pause_button:
		ui.transport_ui.play_pause_button.visible = visible
	if ui.settings_ui and ui.settings_ui.settings_button:
		ui.settings_ui.settings_button.visible = visible
	if ui.layer_loop_toggle:
		ui.layer_loop_toggle.visible = visible
	if ui.settings_ui and ui.settings_ui.mute_speach:
		ui.settings_ui.mute_speach.visible = visible
	if ui.cross:
		ui.cross.visible = visible
	if ui.transport_ui and ui.transport_ui.bpm_label:
		ui.transport_ui.bpm_label.visible = visible
	if ui.transport_ui and ui.transport_ui.metronome:
		ui.transport_ui.metronome.visible = visible
	if ui.transport_ui and ui.transport_ui.metronome_bg:
		ui.transport_ui.metronome_bg.visible = visible
	if ui.chosen_emoticons_label:
		ui.chosen_emoticons_label.visible = visible
	if ui.achievements_panel:
		ui.achievements_panel.visible = visible
	if ui.chaos_pad_ui and ui.chaos_pad_ui.activate_green_chaos_button:
		ui.chaos_pad_ui.activate_green_chaos_button.visible = visible
	if ui.chaos_pad_ui and ui.chaos_pad_ui.activate_purple_chaos_button:
		ui.chaos_pad_ui.activate_purple_chaos_button.visible = visible
	if ui.layer_buttons_container:
		ui.layer_buttons_container.visible = visible
	if ui.transport_ui and ui.transport_ui.progress_bar:
		ui.transport_ui.progress_bar.visible = visible
	
	set_main_buttons_visibility(visible)
	set_recording_buttons_visibility(visible)
	set_drag_and_drop_buttons_visibility(visible)

func set_ring_visibility(ring: int, visible: bool):
	"""Set visibility of all beat sprites for a specific ring"""
	if ring < 0 or ring >= beat_sprites.size():
		return
	
	for beat in range(beat_sprites[ring].size()):
		if beat_sprites[ring][beat]:
			beat_sprites[ring][beat].visible = visible
	
	if ring < template_sprites.size():
		for beat in range(template_sprites[ring].size()):
			if template_sprites[ring][beat]:
				template_sprites[ring][beat].visible = visible

func set_main_buttons_visibility(visible: bool):
	if not ui:
		return
	if ui.save_layout_button:
		ui.save_layout_button.visible = visible
	if ui.load_layout_button:
		ui.load_layout_button.visible = visible
	if ui.clear_layout_button:
		ui.clear_layout_button.visible = visible

func set_bpm_controls_visibility(visible: bool):
	if not ui:
		return

	if ui.transport_ui and ui.transport_ui.bpm_up_button:
		ui.transport_ui.bpm_up_button.visible = visible
	if ui.transport_ui and ui.transport_ui.bpm_down_button:
		ui.transport_ui.bpm_down_button.visible = visible
	if ui.transport_ui and ui.transport_ui.bpm_label:
		ui.transport_ui.bpm_label.visible = visible
	if ui.transport_ui and ui.transport_ui.swing_slider:
		ui.transport_ui.swing_slider.visible = visible
	if ui.transport_ui and ui.transport_ui.swing_label:
		ui.transport_ui.swing_label.visible = visible
	if ui.transport_ui and ui.transport_ui.metronome:
		ui.transport_ui.metronome.visible = visible
	if ui.transport_ui and ui.transport_ui.metronome_bg:
		ui.transport_ui.metronome_bg.visible = visible

func set_recording_buttons_visibility(visible: bool):
	"""Set visibility of recording-related buttons"""
	if ui.record_sample_button0:
		ui.record_sample_button0.visible = visible
	if ui.record_sample_button1:
		ui.record_sample_button1.visible = visible
	if ui.record_sample_button2:
		ui.record_sample_button2.visible = visible
	if ui.record_sample_button3:
		ui.record_sample_button3.visible = visible
	
func set_drag_and_drop_buttons_visibility(visible: bool):
	"""Set visibility of drag-and-drop buttons"""
	if ui.draganddrop_button0:
		ui.draganddrop_button0.visible = visible
	if ui.draganddrop_button1:
		ui.draganddrop_button1.visible = visible
	if ui.draganddrop_button2:
		ui.draganddrop_button2.visible = visible
	if ui.draganddrop_button3:
		ui.draganddrop_button3.visible = visible

func set_green_layer_visibility(visible: bool):
	"""Set visibility of green layer elements"""
	if not ui:
		return
	if ui.activate_green_chaos_button:
		ui.activate_green_chaos_button.visible = visible

func set_purple_layer_visibility(visible: bool):
	"""Set visibility of purple layer elements"""
	ui.chaos_pad_ui.activate_purple_chaos_button.visible = visible

func set_layer_switch_buttons_visibility(visible: bool):
	"""Set visibility of layer switch buttons"""
	if not ui:
		return
	if ui.layer_buttons_container:
		ui.layer_buttons_container.visible = visible

func hide_all():
	"""Hide all interface elements"""
	set_entire_interface_visibility(false)

func show_all():
	"""Show all interface elements"""
	set_entire_interface_visibility(true)
