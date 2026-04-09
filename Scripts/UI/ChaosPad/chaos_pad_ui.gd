extends Control
class_name ChaosPadUI

@export var chaos_pad_triangle_sprite: TextureRect
@export var knob: ChaosPadKnob

# Icons
@export var track_settings: TrackUISettingsRegistry

@export var main_icon: TextureRect
@export var alt_icon: TextureRect

# Curves for visual feedback
@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

func _ready():
	# Connect to EventBus so other scripts don't need a direct reference
	EventBus.track_selected.connect(_on_track_selected)
	EventBus.section_switched.connect(_on_section_changed)

func _on_section_changed(new_section_data: SectionData):
	set_knob_position(new_section_data.get_track_knob_position(SongState.selected_track_index))

func set_knob_position(pos: Vector2):
	knob.position = pos

func _on_track_selected(track: int):
	if SongState.current_section != null:
		set_knob_position(SongState.current_section.get_track_knob_position(track))
	update_track_icons(track)
	start_triangle_color_change(track_settings.get_track(track).track_color, 0.2)

func start_triangle_color_change(new_color: Color, duration: float):
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", new_color, duration)

func update_track_icons(track_index: int):
		var settings := track_settings.get_track(track_index)
		main_icon.texture = settings.button_icon_texture
		alt_icon.texture = settings.chaos_pad_alt_icon

func update_song_icons():
	update_track_icons(-1)  
