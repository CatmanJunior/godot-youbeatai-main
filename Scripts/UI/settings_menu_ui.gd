extends Node
class_name SettingsUI

## Getter only property to check if the settings panel is currently visible
var is_visible: bool:
	get: return settings_panel.visible
	set(value): printerr("Settings Menu UI: Nuh-uh, can't do that here")

##How much the BPM changes when pressing the BPM up/down buttons
@export var bpm_modifier: int = 5
@export var swing_modifier: float = 0.05

@export_category("Settings Panel")
@export var settings_panel: Panel
# @export var settings_button: Button
@export var settings_back_button: Button

# --- clap and add beats---
@export_category("Clap and Add Beats")
@export var button_is_clap: CheckButton
@export var button_add_beats: CheckButton
@export var clap_bias_slider: Slider
@export var clap_adds_beats_toggle: CheckButton

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
@export var bpm_slider: Slider
@export var bpm_progress_bar: ProgressBar

# --- Swing ---
@export_category("Swing")
@export var swing_up_button: Button
@export var swing_down_button: Button
@export var swing_slider: Slider
@export var swing_label: Label
@export var swing_progress_bar: ProgressBar

@export_category("Templates")
@export var template_button: Button

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
	clap_adds_beats_toggle.toggled.connect(_on_clap_adds_beats_toggled)
	# BPM
	bpm_up_button.pressed.connect(_on_bpm_up_pressed)
	bpm_down_button.pressed.connect(_on_bpm_down_pressed)
	bpm_slider.value_changed.connect(_on_bpm_slider_changed)
	# Swing
	swing_up_button.pressed.connect(_on_swing_up_pressed)
	swing_down_button.pressed.connect(_on_swing_down_pressed)
	swing_slider.value_changed.connect(_on_swing_slider_changed)
	recording_delay_slider.value_changed.connect(_on_recording_delay_changed)
	save_to_wav_button.pressed.connect(_on_export_song_pressed)
	restart_button.pressed.connect(_on_restart_button)
	# settings_button.pressed.connect(_on_settings_button_pressed)
	settings_back_button.pressed.connect(_on_settings_button_pressed)
	all_sections_to_mp3.button_up.connect(_on_export_beat_pressed)
	mute_speech.toggled.connect(_on_mute_speech_toggled)

	#incomming Events
	EventBus.toggle_settings_menu_requested.connect(_on_settings_button_pressed)
	EventBus.bpm_changed.connect(_bpm_changed)
	EventBus.swing_changed.connect(_on_swing_changed)


func _process(_delta: float) -> void:
	_update_labels()
	_update_mic_meter()


func _bpm_changed(new_bpm: float) -> void:
	bpm_slider.value = new_bpm
	bpm_progress_bar.value = new_bpm
	bpm_label.text = str(int(new_bpm))

func _on_swing_changed(new_swing: float) -> void:
	swing_slider.value = new_swing
	swing_progress_bar.value = new_swing
	swing_label.text = "Swing: %.2f%%" % (new_swing * 100.0)
	
func _update_mic_meter() -> void:
	microphone_volume_progress_bar.value = GameState.microphone_volume * 100.0


func _update_labels() -> void:
	bpm_label.text = str(SongState.bpm)
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

func _on_clap_adds_beats_toggled(button_pressed: bool):
	GameState.clap_adds_beats = button_pressed

func _on_volume_threshold_changed(value: float):
	GameState.recording_volume_threshold = value

func _on_clap_bias_changed(value: float):
	GameState.clap_bias = value

func _on_bpm_slider_changed(value: float):
	EventBus.bpm_set_requested.emit(int(value))

func _on_bpm_up_pressed():
	EventBus.bpm_up_requested.emit(bpm_modifier)

func _on_bpm_down_pressed():
	EventBus.bpm_down_requested.emit(bpm_modifier)

func _on_swing_up_pressed():
	EventBus.swing_set_requested.emit(swing_slider.value+swing_modifier)

func _on_swing_down_pressed():
	EventBus.swing_set_requested.emit(swing_slider.value-swing_modifier)

func _on_swing_slider_changed(value: float):
	EventBus.swing_set_requested.emit(value)

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
