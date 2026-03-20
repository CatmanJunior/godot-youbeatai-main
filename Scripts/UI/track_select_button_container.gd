extends Control
class_name TrackSelectButtonContainer

@export var outline_textures: Array[Texture2D]
@export var filled_textures: Array[Texture2D]
@export var icon_textures: Array[Texture2D]
@export var track_buttons: Array[TrackSelectButton]



func _ready():
	for button in track_buttons:
		button.texture_normal = icon_textures[button.track_index]
		button.outline_texture = outline_textures[button.track_index]
		button.filled_texture = filled_textures[button.track_index]
		button.outline_rect.texture = button.outline_texture

		button.track_button_pressed.connect(_on_track_button_pressed)
		if button.is_synth_track:
			button.background.modulate = GameState.colors[button.track_index]

	track_buttons[GameState.selected_track_index].set_button_selected(true)

func _process(_delta: float) -> void:
	var progression = GameState.bar_progress

	track_buttons[GameState.selected_track_index].update_outline(progression)

func _on_track_button_pressed(track_index: int):
	for button in track_buttons:
		button.set_button_selected(false)
	track_buttons[track_index].set_button_selected(true)

	if not track_buttons[track_index].is_synth_track:
		EventBus.play_track_requested.emit(track_index)

	if GameState.track_button_add_beats:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)

	EventBus.track_selected.emit(track_index)
