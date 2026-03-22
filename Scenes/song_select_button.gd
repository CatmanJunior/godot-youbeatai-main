extends Button
class_name SongSelectButton

@export var filled_song_texture: Texture2D
@export var outline_song_texture: Texture2D

@export var sprite_texture: Control
var is_toggled: bool = false

func _pressed() -> void:
	_select_song()

func _select_song():
	is_toggled = !is_toggled
	if is_toggled:
		sprite_texture.sprite_texture = filled_song_texture
	else:
		sprite_texture.sprite_texture = outline_song_texture

	GameState.loop_sections = is_toggled
	EventBus.song_select_button_toggled.emit(is_toggled)
