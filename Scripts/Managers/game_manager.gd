extends Node

@export var notes: Notes
var time: float = 0.0

var first_tts_done: bool = false

func _ready():
	EventBus.fullscreen_toggle_requested.connect(_toggle_fullscreen)
	GameState.notes = notes

func _process(delta: float):
	time += delta

func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN