extends Node

## Global game state singleton (autoload).
## Provides easy access to session state.

func reset() -> void:
	SongState.reset()

	# Playback
	playing = false
	current_beat = 0
	beat_progress = 0.0
	bar_progress = 0.0
	beat_duration = 0.5

	# Recording
	is_recording = false
	SceneChanger.restart()

var notes: Notes

# -- TO BE IMPLEMENTED --
var tutorial_activated: bool = false
var use_tutorial: bool = false
var loop_sections: bool = false

# -- Export settings --
var export_name: String = ""
var export_mail: String = ""

# ---- Settings ----

var microphone_volume: float = 0.0

var recording_delay_seconds: float = 0.0

var recording_volume_threshold: float = 0.1

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

## Duration of one beat subdivision in seconds (60 / bpm / beats_per_bar).
var beat_duration: float = 0.5

# -- Recording --

var is_recording: bool = false


# -- Initialization --
func _ready() -> void:
	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.recording_started.connect(func(_rd: RecordingData): is_recording = true)
	EventBus.recording_stopped.connect(func(_rd: RecordingData): is_recording = false)
	EventBus.restart_requested.connect(reset)
