extends Node

var green_synth_index = 4
var purple_synth_index = 5

@export var activate_green_chaos_button: Sprite2D
@export var activate_purple_chaos_button: Sprite2D
@export var dotted_synth_textures: Array[Texture2D]
@export var outline_synth_textures: Array[Texture2D]


@export var corners: Array[Node2D] = []
@export var chaos_pad_triangle_sprite: Sprite2D


enum ChaosPadMode {None, SampleMixing, SynthMixing}
var chaos_pad_mode = ChaosPadMode.None

var _beat_ring_ui: Node

# Called by ui_manager._ready()
func initialize(ui: Node) -> void:
	_beat_ring_ui = ui.beat_ring_ui

	var colors = ui.colors
	activate_green_chaos_button.self_modulate = colors[4]
	activate_purple_chaos_button.self_modulate = colors[5]

	var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	green_back.self_modulate = colors[4]

	var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	purple_back.self_modulate = colors[5]

func update(_delta: float) -> void:
	_update_ring_button_outlines()
	_update_synth_button_outlines()

func _update_ring_button_outlines() -> void:
	var outlines: Array[Sprite2D] = []
	for btn in _beat_ring_ui.instrument_buttons:
		outlines.append(btn.find_child("OutlineSprite") as Sprite2D)

	if chaos_pad_mode == ChaosPadMode.SampleMixing:
		var active_ring = GameState.selected_track
		for i in range(4):
			outlines[i].texture = _beat_ring_ui.filled_beat_textures[i] if active_ring == i else _beat_ring_ui.outline_beat_textures[i]
	else:
		for i in range(4):
			outlines[i].texture = _beat_ring_ui.outline_beat_textures[i]

func _update_synth_button_outlines() -> void:
	var progression = float(GameState.current_beat + (GameState.beat_timer / GameState.time_per_beat)) / float(GameState.beats_amount)
	if is_nan(progression):
		progression = 0.0

	var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	var green_outline = activate_green_chaos_button.find_child("OutlineSprite") as Sprite2D
	var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	var purple_outline = activate_purple_chaos_button.find_child("OutlineSprite") as Sprite2D

	if chaos_pad_mode == ChaosPadMode.SynthMixing:
		var active_synth = GameState.selected_track

		if active_synth == green_synth_index and outline_synth_textures.size() > 0:
			green_back.visible = true
			green_outline.texture = outline_synth_textures[0]
			green_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			green_back.visible = false
			if dotted_synth_textures.size() > 0:
				green_outline.texture = dotted_synth_textures[0]

		if active_synth == purple_synth_index and outline_synth_textures.size() > 1:
			purple_back.visible = true
			purple_outline.texture = outline_synth_textures[1]
			purple_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			purple_back.visible = false
			if dotted_synth_textures.size() > 1:
				purple_outline.texture = dotted_synth_textures[1]
	else:
		green_back.visible = false
		purple_back.visible = false
		if dotted_synth_textures.size() > 0:
			green_outline.texture = dotted_synth_textures[0]
		if dotted_synth_textures.size() > 1:
			purple_outline.texture = dotted_synth_textures[1]
		green_outline.rotation_degrees = 30.0
		purple_outline.rotation_degrees = 30.0
