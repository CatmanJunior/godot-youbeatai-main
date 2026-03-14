extends Sprite2D

@export var track: int = 0
@export var button: Button

var color_is_changing: bool = false

func _ready():
	button.button_up.connect(_on_press)

func _on_press():
	_button_behaviour()

	EventBus.track_select_button_pressed.emit(track)


func _button_sound():
	EventBus.play_ring_requested.emit(track)


func _button_behaviour():
	_button_sound()

	
	if GameState.track_button_add_beats:
		EventBus.beat_set_requested.emit(track, GameState.current_beat, true)

	#TODO do this with a event
	if GameState.selected_track != track:
		%Colors.start_color_change(track, 0.3)

