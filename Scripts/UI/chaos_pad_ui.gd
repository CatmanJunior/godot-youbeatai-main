extends Node

# Called by ui_manager._ready()
func initialize(_ui: Node) -> void:
	pass

func update(_delta: float) -> void:
	_update_ring_button_outlines()
	_update_synth_button_outlines()

func _update_ring_button_outlines() -> void:
	var ui = get_parent()
	var outlines: Array[Sprite2D] = []
	for btn in ui.instrument_buttons:
		outlines.append(btn.find_child("OutlineSprite") as Sprite2D)

	if ui.chaos_pad_mode == ui.ChaosPadMode.SampleMixing:
		var mixing_manager = ui.get_parent().get_node("MixingManager")
		var active_ring = mixing_manager.samples_mixing_active_ring
		for i in range(4):
			outlines[i].texture = ui.filled_beat_textures[i] if active_ring == i else ui.outline_beat_textures[i]
	else:
		for i in range(4):
			outlines[i].texture = ui.outline_beat_textures[i]

func _update_synth_button_outlines() -> void:
	var ui = get_parent()
	var progression = float(GameState.current_beat + (GameState.beat_timer / GameState.time_per_beat)) / float(GameState.beats_amount)
	if is_nan(progression):
		progression = 0.0

	var green_back = ui.activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	var green_outline = ui.activate_green_chaos_button.find_child("OutlineSprite") as Sprite2D
	var purple_back = ui.activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	var purple_outline = ui.activate_purple_chaos_button.find_child("OutlineSprite") as Sprite2D

	if ui.chaos_pad_mode == ui.ChaosPadMode.SynthMixing:
		var mixing_manager = ui.get_parent().get_node("MixingManager")
		var active_synth = mixing_manager.synth_mixing_active_synth

		if active_synth == 0 and ui.outline_synth_textures.size() > 0:
			green_back.visible = true
			green_outline.texture = ui.outline_synth_textures[0]
			green_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			green_back.visible = false
			if ui.dotted_synth_textures.size() > 0:
				green_outline.texture = ui.dotted_synth_textures[0]

		if active_synth == 1 and ui.outline_synth_textures.size() > 1:
			purple_back.visible = true
			purple_outline.texture = ui.outline_synth_textures[1]
			purple_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			purple_back.visible = false
			if ui.dotted_synth_textures.size() > 1:
				purple_outline.texture = ui.dotted_synth_textures[1]
	else:
		green_back.visible = false
		purple_back.visible = false
		if ui.dotted_synth_textures.size() > 0:
			green_outline.texture = ui.dotted_synth_textures[0]
		if ui.dotted_synth_textures.size() > 1:
			purple_outline.texture = ui.dotted_synth_textures[1]
		green_outline.rotation_degrees = 30.0
		purple_outline.rotation_degrees = 30.0
