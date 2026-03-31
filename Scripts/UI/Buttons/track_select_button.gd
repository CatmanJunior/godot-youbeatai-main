extends TextureButton
class_name TrackSelectButton

@export_category("Components")
@export var outline_rect: TextureRect
@export var glow_rect: TextureRect
@export var icon_label: Label

@export_category("Synth Only")
@export var background: TextureRect
@export var is_synth_track: bool = false

@export_category("Track Info")
@export var track_index: int = 0

var outline_texture: Texture2D
var filled_texture: Texture2D

var color_is_changing: bool = false


signal track_button_pressed(track_index: int)

func _ready():
	self.button_up.connect(_on_press)

func update_outline(progression:float) -> void:
	if is_synth_track:
		outline_rect.rotation_degrees = progression * 360.0 + 30.0

func set_button_selected(active: bool) -> void:
	if active:
		outline_rect.texture = filled_texture
	else:
		outline_rect.texture = outline_texture

	if is_synth_track:
		background.visible = active

func _on_press():
	emit_signal("track_button_pressed", track_index)
