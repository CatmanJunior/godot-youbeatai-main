extends Button
class_name TrackSelectButton

@export_category("Components")
@export var outline_rect: TextureRect
@export var glow_rect: TextureRect
@export var icon_rect: TextureRect

@export_category("Synth Only")
@export var background: TextureRect
@export var is_synth_track: bool = false

@export_category("Track Info")
@export var track_index: int = 0

var track_ui_settings: TrackUISettingsBase


var color_is_changing: bool = false


signal track_button_pressed(track_index: int)

func _ready():
	self.button_up.connect(_on_press)

func init(p_track_index: int, p_track_ui_settings: TrackUISettingsBase):
	self.track_index = p_track_index
	self.track_ui_settings = p_track_ui_settings
	self.icon_rect.texture = track_ui_settings.button_icon_texture
	self.outline_rect.texture = track_ui_settings.button_outline_texture
	

func update_outline(progression:float) -> void:
	if is_synth_track:
		outline_rect.rotation_degrees = progression * 360.0 + 30.0

func set_button_selected(active: bool) -> void:
	if active:
		outline_rect.texture = track_ui_settings.button_filled_texture
	else:
		outline_rect.texture = track_ui_settings.button_outline_texture

	if is_synth_track:
		background.visible = active

func _on_press():
	emit_signal("track_button_pressed", track_index)
