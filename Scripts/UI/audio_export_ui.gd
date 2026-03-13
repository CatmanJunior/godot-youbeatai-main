extends Node

# Private state
var _saving_label_active: bool = false
var _saving_label_timer: float = 0.0

# Called by ui_manager._ready()
func initialize(ui: Node) -> void:
	ui.all_sections_to_mp3.button_up.connect(func():
		_export_song_wav()
		ui.settings_panel.visible = false
	)

	ui.save_to_wav_button.pressed.connect(func():
		_export_beat_wav()
		ui.settings_panel.visible = false
	)

	ui.mute_speach.pressed.connect(DisplayServer.tts_stop)

	ui.restart_button.pressed.connect(_on_restart_button)

	ui.skip_tutorial_button.pressed.connect(func():
		ui.set_entire_interface_visibility(true)
		ui.achievements_panel.visible = false
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
	)

	ui.settings_button.pressed.connect(func():
		ui.settings_panel.visible = !ui.settings_panel.visible
	)

	ui.settings_back_button.pressed.connect(func():
		ui.settings_panel.visible = !ui.settings_panel.visible
	)

func update(delta: float) -> void:
	_update_saving_label(delta, get_parent())

func show_saving_label(path: String) -> void:
	var ui = get_parent()
	if ui.saving_label:
		ui.saving_label.text = "Saved to: " + path.get_file()
	_saving_label_active = true
	_saving_label_timer = 0.0

func _update_saving_label(delta: float, ui: Node) -> void:
	if _saving_label_active and _saving_label_timer < 4:
		_saving_label_timer += delta
	else:
		_saving_label_active = false
	ui.saving_label.visible = _saving_label_active

func _export_song_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = GameState.current_bpm

	var path: String = AudioSavingManager.save_realtime_recorded_song_as_file(
		recording, voice_over, bpm)
	if path != "":
		show_saving_label(path)

func _export_beat_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = GameState.current_bpm
	var section_index: int = GameState.current_section_index
	var beats_amount: int = GameState.current_beats_amount
	var base_time_per_beat: float = GameState.current_base_time_per_beat

	var path: String = AudioSavingManager.save_realtime_recorded_beat_as_file(
		recording, voice_over, bpm, section_index, beats_amount, base_time_per_beat)
	if path != "":
		show_saving_label(path)

func _on_restart_button() -> void:
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
