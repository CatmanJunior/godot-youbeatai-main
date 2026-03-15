extends Sprite2D

@export var track_index: int = 0
@export var button: Button
@export var is_synth_track: bool = false

@export var outline_texture: Texture2D
@export var filled_texture: Texture2D

var color_is_changing: bool = false

var _background: Sprite2D
var _outline: Sprite2D

func _ready():
	button.button_up.connect(_on_press)
	_background = find_child("BackSprite") as Sprite2D
	_outline = find_child("OutlineSprite") as Sprite2D

	var colors = %UiManager.colors

	if is_synth_track:
		self_modulate = colors[track_index]
		_background.self_modulate = colors[track_index]

func _process(_delta: float) -> void:
	_update_outline()

func _update_outline() -> void:
	var progression = GameState.bar_progress
	if GameState.selected_track_index == track_index:
		_outline.texture = filled_texture
		if is_synth_track:
			_background.visible = true
			_outline.rotation_degrees = progression * 360.0 + 30.0
	else:
		if is_synth_track:
			_background.visible = false
		_outline.texture = outline_texture

func _on_press():
	if not is_synth_track:
		EventBus.play_sample_track_requested.emit(track_index)

	if GameState.track_button_add_beats:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)

	#TODO do this with a event, or in the chaospad ui
	if GameState.selected_track_index != track_index:
		%Colors.start_color_change(track_index, 0.3)

	GameState.selected_track_index = track_index

	EventBus.track_select_button_pressed.emit(track_index)
	EventBus.track_selected.emit(track_index)
