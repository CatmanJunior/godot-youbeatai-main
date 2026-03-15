extends Node
class_name ChaosPadUI

@export var corners: Array[Node2D] = []
@export var chaos_pad_triangle_sprite: Sprite2D
@export var knob: Sprite2D

# Icons
@export var main_icons: Array[Texture2D] = [] # 4 for rings
@export var alt_icons: Array[Texture2D] = [] # 4 for rings
@export var main_icon_synths: Array[Texture2D] = [] # 2 for synths
@export var alt_icon_synths: Array[Texture2D] = [] # 2 for synths
@export var main_icon_song: Texture2D
@export var alt_icon_song: Texture2D

@export var main_icon: Sprite2D
@export var alt_icon: Sprite2D

# Curves for visual feedback
@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

# Visual state
var outer_triangle_size: float = 60.0

func start_triangle_color_change(color_index: int, duration: float):
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", %Colors.colors[color_index], duration)

func update_track_icons(track_index: int):
	if track_index < GameState.sections[0].SAMPLE_TRACKS_PER_SECTION:
		if main_icon and track_index < main_icons.size():
			main_icon.texture = main_icons[track_index]
		if alt_icon and track_index < alt_icons.size():
			alt_icon.texture = alt_icons[track_index]
	else:
		var synth_index = track_index - GameState.sections[0].SAMPLE_TRACKS_PER_SECTION
		if main_icon and synth_index < main_icon_synths.size():
			main_icon.texture = main_icon_synths[synth_index]
		if alt_icon and synth_index < alt_icon_synths.size():
			alt_icon.texture = alt_icon_synths[synth_index]

func update_song_icons():
	if main_icon and main_icon_song:
		main_icon.texture = main_icon_song
	if alt_icon and alt_icon_song:
		alt_icon.texture = alt_icon_song
