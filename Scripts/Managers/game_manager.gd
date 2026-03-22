extends Node


var time: float = 0.0

var first_tts_done: bool = false

func _ready():
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.export_requested.connect(_on_save_to_wav_requested)
	EventBus.save_to_mp3_requested.connect(_on_save_to_mp3)

	read_json_from_previous_scene_and_set_values()

	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)

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

func _on_save_to_wav_requested():
	_export_beat_wav()

func _on_save_to_mp3():
	_export_song_wav()


func _export_song_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = GameState.bpm

	var path: String = AudioSavingManager.save_realtime_recorded_song_as_file(
		recording, voice_over, bpm)
	if path != "":
		EventBus.saving_completed.emit(path)

func _export_beat_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = GameState.bpm
	var section_index: int = GameState.current_section_index
	var beats_amount: int = GameState.total_beats
	var base_time_per_beat: float = GameState.beat_duration

	var path: String = AudioSavingManager.save_realtime_recorded_beat_as_file(
		recording, voice_over, bpm, section_index, beats_amount, base_time_per_beat)
	if path != "":
		EventBus.saving_completed.emit(path)

func utterance_end(utterance_id: int):
	EventBus.utterance_ended.emit(utterance_id)


func text_without_emoticons(text: String) -> String:
	var emoticon_pattern = r"(:\)|:\(|:D|:P|;\)|<3|:\*|:\|)"
	var regex = RegEx.new()
	regex.compile(emoticon_pattern)
	return regex.sub(text, "")

func show_countdown():
	EventBus.countdown_show_requested.emit()

func _process(delta: float):
	time += delta

func read_json_from_previous_scene_and_set_values():
	pass
