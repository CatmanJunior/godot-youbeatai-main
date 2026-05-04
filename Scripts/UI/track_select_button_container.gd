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

	EventBus.track_select_button_visibility_requested.connect(_on_track_select_button_visibility_requested)
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)
	call_deferred("_set_initial_track")

func _on_ui_visibility_requested(p_element: int, p_visible: bool) -> void:
	if p_element == UIVisibilityListener.UIElement.ENTIRE_INTERFACE:
		for button in track_buttons:
			button.visible = p_visible

func _on_track_select_button_visibility_requested(p_track: int, p_visible: bool) -> void:
	if p_track >= 0 and p_track < track_buttons.size():
		track_buttons[p_track].visible = p_visible

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

	if GameState.tutorial_activated:
		if track_index == 0:
			EventBus.clap_stomp_detected.emit(0)
		elif track_index == 1:
			EventBus.clap_stomp_detected.emit(1)
			
