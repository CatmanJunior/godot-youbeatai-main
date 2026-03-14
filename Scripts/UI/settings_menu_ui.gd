extends Node

# --- clap and add beats---
@export var button_is_clap: CheckButton
@export var button_add_beats: CheckButton
@export var clap_bias_slider: Slider

# --- Recording ---
@export var volume_threshold: Slider
@export var recording_delay_slider: Slider
@export var recording_delay_label: Label

# --- BPM ---
@export var bpm_label: Label
@export var bpm_up_button: Button
@export var bpm_down_button: Button

# --- Swing ---
@export var swing_slider: Slider
@export var swing_label: Label

@export var all_sections_to_mp3: Button
@export var save_to_wav_button: Button
@export var restart_button: Button
@export var skip_tutorial_button: Button
@export var settings_panel: Panel
@export var settings_button: Button
@export var settings_back_button: Button
@export var saving_label: Label
@export var mute_speech: CheckButton

func _ready():
	button_is_clap.toggled.connect(_on_button_is_clap_toggled)
	button_add_beats.toggled.connect(_on_button_add_beats_toggled)
	volume_threshold.value_changed.connect(_on_volume_threshold_changed)
	clap_bias_slider.value_changed.connect(_on_clap_bias_changed)
	bpm_up_button.pressed.connect(_on_bpm_up_pressed)
	bpm_down_button.pressed.connect(_on_bpm_down_pressed)
	swing_slider.value_changed.connect(_on_swing_changed)

func _process(_delta: float) -> void:
	_update_labels()

func _on_add_beats_toggled(button_pressed: bool):
	GameState.track_button_add_beats = button_pressed

func _on_button_is_clap_toggled(button_pressed: bool):
	GameState.button_is_clap = button_pressed

func _on_button_add_beats_toggled(button_pressed: bool):
	GameState.track_button_add_beats = button_pressed

func _on_volume_threshold_changed(value: float):
	GameState.recording_volume_threshold = value

func _on_clap_bias_changed(value: float):
	GameState.clap_bias = value

func _on_bpm_up_pressed():
	EventBus.bpm_up_requested.emit(5)

func _on_bpm_down_pressed():
	EventBus.bpm_down_requested.emit(5)

func _on_swing_changed(value: float):
	GameState.swing = value

func _update_labels() -> void:
	bpm_label.text = str(GameState.current_bpm)
	recording_delay_label.text = "%.2fs" % recording_delay_slider.value
	swing_label.text = "Swing: %.2f%%" % (swing_slider.value * 100.0)



# Private state
var _saving_label_active: bool = false
var _saving_label_timer: float = 0.0

# Called by ui_manager._ready()
func initialize(ui: Node) -> void:
	all_sections_to_mp3.button_up.connect(func():
		_export_song_wav()
		settings_panel.visible = false
	)

	save_to_wav_button.pressed.connect(func():
		_export_beat_wav()
		settings_panel.visible = false
	)

	mute_speech.pressed.connect(DisplayServer.tts_stop)

	restart_button.pressed.connect(_on_restart_button)

	skip_tutorial_button.pressed.connect(func():
		ui.set_entire_interface_visibility(true)
		ui.achievements_panel.visible = false
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
	)

	settings_button.pressed.connect(func():
		settings_panel.visible = !settings_panel.visible
	)

	settings_back_button.pressed.connect(func():
		settings_panel.visible = !settings_panel.visible
	)

func update(delta: float) -> void:
	_update_saving_label(delta)

func show_saving_label(path: String) -> void:
	if saving_label:
		saving_label.text = "Saved to: " + path.get_file()
	_saving_label_active = true
	_saving_label_timer = 0.0

func _update_saving_label(delta: float) -> void:
	if _saving_label_active and _saving_label_timer < 4:
		_saving_label_timer += delta
	else:
		_saving_label_active = false
	saving_label.visible = _saving_label_active

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