extends Node


@export var notes: Notes
var time: float = 0.0

var first_tts_done: bool = false

func _ready():
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.fullscreen_toggle_requested.connect(_toggle_fullscreen)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	GameState.notes = notes

func _on_restart_requested():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

	var user_path = ProjectSettings.globalize_path("user://")
	var files_to_reset = [
		user_path + "/chosen_emoticons.json",
		user_path + "/chosen_soundbank.json",
		user_path + "/beats_amount.txt",
		user_path + "/use_tutorial.txt",
		user_path + "/use_achievements.txt"
	]

	for file_path in files_to_reset:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)

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