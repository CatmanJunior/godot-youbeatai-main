extends Node

## Global game state singleton (autoload).
## Provides easy access to playback state, settings, and UI-related data
## without needing %UniqueNode references everywhere.
##
## Song-related state (sections, tracks, soundbank, tempo) lives in SongState.

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

var notes: Notes

# -- TO BE IMPLEMENTED --
var songModeActive: bool = false
var tutorialActivated: bool = false
var loop_sections: bool = false

##Not Tested
func Text_without_emoticons(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r":[^:\s]+:")
	return regex.sub(text, "")

var colors: Array[Color] = [
	Color(0.9019608, 0.29411766, 0.5568628, 1),
	Color(0.972549, 0.52156866, 0.17254902, 1),
	Color(0.2627451, 0.79607844, 0.5294118, 1),
	Color(0.011764706, 0.8235294, 0.93333334, 1),
	Color(1, 1, 0, 1),
	Color(0.516666, 0, 1, 1),
	Color(0.61960787, 0.6117647, 0.8980392, 1)
]

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

var metronome_enabled: bool = false

var mute_speech: bool = false

# -- Players and buses --
var audio_players: Array[TrackPlayerBase] = []

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
	EventBus.recording_started.connect(func(): is_recording = true)
	EventBus.recording_stopped.connect(func(_audio): is_recording = false)
