extends Control
class_name ChaosPadUI

@export var chaos_pad_triangle_sprite: TextureRect
@export var knob: ChaosPadKnob

# Icons
@export var track_settings: TrackSettingsRegistry

@export var main_icon: TextureRect
@export var alt_icon: TextureRect

# Curves for visual feedback
@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

func start_triangle_color_change(color_index: int, duration: float):
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", GameState.colors[color_index], duration)

func update_track_icons(track_index: int):
		var settings := track_settings.get_track(track_index)
		main_icon.texture = settings.button_icon_texture
		alt_icon.texture = settings.chaos_pad_alt_icon

func update_song_icons():
	update_track_icons(-1)  
