extends Node

## Global game state singleton (autoload).
## Provides easy access to session state.
var notes: Notes

var restarting: bool = false

##Set to true to use achievements after tutorial.
var use_achievements: bool = true
## used to set when to activate the achievements (after tutorial or immediately)
var achievements_active: bool = false

## Current energy points (0–100). Managed by EnergyManager.
var energy_points: float = 0.0

var tutorial_activated: bool = false
var use_tutorial: bool = false
var show_template: bool = false
var added_layer: bool = false

# -- Export settings --
var export_name: String = ""
var export_mail: String = ""

# ---- Settings ----

var microphone_volume: float = 0.0

var recording_delay_seconds: float = 0.0

var recording_volume_threshold: float = 1.0

var track_button_add_beats: bool = false

var button_is_clap: bool = false

var clap_bias: float = 0.0

var clap_adds_beats: bool = false

var metronome_enabled: bool = false

var mute_speech: bool = false

# -- Playback --
var playing: bool = false
var current_beat: int = 0

## This is a value from 0 to 1 representing how far along the current beat is.
var beat_progress: float = 0.0

## This is a value from 0 to 1 representing how far along the current bar is.
var bar_progress: float = 0.0

# -- Recording --
var is_recording: bool = false

var loop_cursor: int = 0

#-- Song mode (vs. track mode) --
var song_mode_active: bool = false


func reset() -> void:
	restarting = true
	SongState.reset()
	
	notes = null

	# Tutorial / achievements
	use_achievements = true
	achievements_active = false
	energy_points = 0.0
	tutorial_activated = false
	use_tutorial = false
	show_template = false
	added_layer = false

	# Export settings
	export_name = ""
	export_mail = ""

	# Settings
	microphone_volume = 0.0
	recording_delay_seconds = 0.0
	recording_volume_threshold = 1.0
	track_button_add_beats = false
	button_is_clap = false
	clap_bias = 0.0
	clap_adds_beats = false
	metronome_enabled = false
	mute_speech = false

	# Playback
	playing = false
	current_beat = 0
	beat_progress = 0.0
	bar_progress = 0.0

	# Recording
	is_recording = false

	loop_cursor = 0
	song_mode_active = false

	restarting = false
	SceneChanger.restart()

# -- Initialization --
func _ready() -> void:
	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.recording_started.connect(func(_rd: RecordingData): is_recording = true)
	EventBus.recording_stopped.connect(func(_rd: RecordingData): is_recording = false)
	EventBus.restart_requested.connect(reset)
