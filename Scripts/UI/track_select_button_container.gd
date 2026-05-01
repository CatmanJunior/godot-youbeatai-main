extends Control
class_name TrackSelectButtonContainer

@export var track_UI_settings: TrackUISettingsRegistry
@export var track_buttons: Array[TrackSelectButton]

func _ready():
	for i in range(track_buttons.size()):
		var button = track_buttons[i]
		var settings := track_UI_settings.get_track(i)
		button.init(i, settings)

		button.track_button_pressed.connect(_on_track_button_pressed)

	call_deferred("_set_initial_track")

func _set_initial_track():
	track_buttons[0].set_button_selected(true)
	EventBus.track_selected.emit(0)

func _process(_delta: float) -> void:
	var progression = GameState.bar_progress

	track_buttons[SongState.selected_track_index].update_outline(progression)

func _on_track_button_pressed(track_index: int):
	for button in track_buttons:
		button.set_button_selected(false)
	track_buttons[track_index].set_button_selected(true)

	if track_buttons[track_index].is_synth_track:
		track_buttons[track_index].background.modulate = track_UI_settings.get_track(track_index).track_color

	if not track_buttons[track_index].is_synth_track:
		EventBus.play_track_requested.emit(track_index)

	if GameState.track_button_add_beats:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)

	EventBus.track_selected.emit(track_index)
