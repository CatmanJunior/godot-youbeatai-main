extends Node
class_name SettingsUI

## Getter only property to check if the settings panel is currently visible
var is_visible: bool:
	get: return settings_panel.visible
	set(value): printerr("Settings Menu UI: Nuh-uh, can't do that here")

##Howmuch the BPM changes when pressing the BPM up/down buttons
@export var bmp_modifier: int = 5

@export_category("Settings Panel")
@export var settings_panel: Panel
# @export var settings_button: Button
@export var settings_back_button: Button

# --- clap and add beats---
@export_category("Clap and Add Beats")
@export var button_is_clap: CheckButton
@export var button_add_beats: CheckButton
@export var clap_bias_slider: Slider

# --- Recording ---
@export_category("Recording")
@export var recording_volume_threshold_slider: Slider
@export var microphone_volume_progress_bar: ProgressBar
@export var recording_delay_slider: Slider
@export var recording_delay_label: Label

# --- BPM ---
@export_category("BPM")
@export var bpm_label: Label
@export var bpm_up_button: Button
@export var bpm_down_button: Button

# --- Swing ---
@export_category("Swing")
@export var swing_slider: Slider
@export var swing_label: Label


@export_category("Other")
@export var all_sections_to_mp3: Button
@export var save_to_wav_button: Button
@export var restart_button: Button
@export var metronome_toggle: CheckButton
@export var mute_speech: CheckButton


func _ready():
	metronome_toggle.toggled.connect(_on_metronome_toggle_toggled)
	button_is_clap.toggled.connect(_on_button_is_clap_toggled)
	button_add_beats.toggled.connect(_on_button_add_beats_toggled)
	recording_volume_threshold_slider.value_changed.connect(_on_volume_threshold_changed)
	clap_bias_slider.value_changed.connect(_on_clap_bias_changed)
	bpm_up_button.pressed.connect(_on_bpm_up_pressed)
	bpm_down_button.pressed.connect(_on_bpm_down_pressed)
	swing_slider.value_changed.connect(_on_swing_changed)
	recording_delay_slider.value_changed.connect(_on_recording_delay_changed)
	save_to_wav_button.pressed.connect(_on_export_song_pressed)
	restart_button.pressed.connect(_on_restart_button)
	# settings_button.pressed.connect(_on_settings_button_pressed)
	settings_back_button.pressed.connect(_on_settings_button_pressed)
	all_sections_to_mp3.button_up.connect(_on_export_beat_pressed)
	mute_speech.toggled.connect(_on_mute_speech_toggled)
	EventBus.toggle_settings_menu_requested.connect(_on_settings_button_pressed)

func _process(_delta: float) -> void:
	_update_labels()
	_update_mic_meter()


func _update_mic_meter() -> void:
	microphone_volume_progress_bar.value = GameState.microphone_volume * 100.0


func _update_labels() -> void:
	bpm_label.text = str(GameState.bpm)
	recording_delay_label.text = "%.2fs" % recording_delay_slider.value
	swing_label.text = "Swing: %.2f%%" % (swing_slider.value * 100.0)

# --- Event Handlers ---
func _on_mute_speech_toggled(button_pressed: bool):
	GameState.mute_speech = button_pressed

func _on_settings_button_pressed():
	settings_panel.visible = !settings_panel.visible

func _on_recording_delay_changed(value: float) -> void:
	GameState.recording_delay_seconds = value

func _on_button_is_clap_toggled(button_pressed: bool):
	GameState.button_is_clap = button_pressed

func _on_button_add_beats_toggled(button_pressed: bool):
	GameState.track_button_add_beats = button_pressed

func _on_volume_threshold_changed(value: float):
	GameState.recording_volume_threshold = value

func _on_clap_bias_changed(value: float):
	GameState.clap_bias = value

func _on_bpm_up_pressed():
	EventBus.bpm_up_requested.emit(bmp_modifier)

func _on_bpm_down_pressed():
	EventBus.bpm_down_requested.emit(bmp_modifier)

func _on_swing_changed(value: float):
	GameState.swing = value

func _on_export_beat_pressed():
	EventBus.open_export_dialog_requested.emit(false) # false for beat export, true for song export
	settings_panel.visible = false

func _on_export_song_pressed():
	EventBus.open_export_dialog_requested.emit(true) # false for beat export, true for song export
	settings_panel.visible = false
	
func _on_restart_button() -> void:
	EventBus.restart_requested.emit()

func _on_metronome_toggle_toggled(button_pressed: bool):
	GameState.metronome_enabled = button_pressed
