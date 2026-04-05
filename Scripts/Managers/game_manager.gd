extends Node


@export var notes: Notes
var time: float = 0.0

var first_tts_done: bool = false

func _ready():
	EventBus.fullscreen_toggle_requested.connect(_toggle_fullscreen)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	GameState.notes = notes



func utterance_end(utterance_id: int):
	EventBus.utterance_ended.emit(utterance_id)

func text_without_emoticons(text: String) -> String:
	var emoticon_pattern = r"(:\)|:\(|:D|:P|;\)|<3|:\*|:\|)"
	var regex = RegEx.new()
	regex.compile(emoticon_pattern)
	return regex.sub(text, "")

func _process(delta: float):
	time += delta

func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN