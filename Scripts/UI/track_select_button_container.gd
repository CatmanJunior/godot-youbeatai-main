extends Control
class_name TrackSelectButtonContainer

@export var track_settings: TrackSettingsRegistry
@export var track_buttons: Array[TrackSelectButton]



func _ready():
	for button in track_buttons:
		var settings := track_settings.get_track(button.track_index)
		if settings != null:
			button.texture_normal = settings.button_icon_texture
			button.outline_texture = settings.button_outline_texture
			button.filled_texture = settings.button_filled_texture
			button.outline_rect.texture = button.outline_texture

		button.track_button_pressed.connect(_on_track_button_pressed)


	call_deferred("_set_initial_track")

func _set_initial_track():
	track_buttons[0].set_button_selected(true)
	EventBus.track_selected.emit(0)

func _process(_delta: float) -> void:
	var progression = GameState.bar_progress

	track_buttons[GameState.selected_track_index].update_outline(progression)

func _on_track_button_pressed(track_index: int):
	for button in track_buttons:
		button.set_button_selected(false)
	track_buttons[track_index].set_button_selected(true)

	if track_buttons[track_index].is_synth_track:
		track_buttons[track_index].background.modulate = track_settings.get_track(track_index).track_color

	if not track_buttons[track_index].is_synth_track:
		EventBus.play_track_requested.emit(track_index)

	if GameState.track_button_add_beats:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)

	EventBus.track_selected.emit(track_index)
