extends Node

## Global game state singleton (autoload).
## Provides easy access to sections, playback state, and common data
## without needing %UniqueNode references everywhere.

var song_track: SongTrackData = SongTrackData.new()

func reset() -> void:
	# Sections & Tracks
	song_track.clear()
	sections.clear()
	current_section = null
	current_section_index = -1
	selected_track_index = 0

	# Playback
	playing = false
	bpm = 120
	current_beat = 0
	total_beats = BEATS_AMOUNT_DEFAULT
	swing = 0.05
	beat_progress = 0.0
	bar_progress = 0.0
	beat_duration = 0.5

	# Recording
	is_recording = false

var notes: Notes

const BEATS_AMOUNT_DEFAULT: int = 16

# -- TO BE IMPLEMENTED --
var songModeActive: bool = false
var tutorialActivated: bool = false
var loop_sections: bool = false
var selected_soundbank: Dictionary = {}

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

# -- Sections & Tracks --

var sections: Array[SectionData] = []
var current_section: SectionData = null
var current_section_index: int:
	get:
		if current_section:
			return current_section.index
		else:
			return -1
var selected_track_index: int = 0
var selected_track: TrackData:
	get:
		if current_section and selected_track_index >= 0 and selected_track_index < current_section.tracks.size():
			return current_section.tracks[selected_track_index]
		return null

# -- Playback --
var playing: bool = false
var bpm: int = 120
var current_beat: int = 0
var total_beats: int = 16
var swing: float = 0.05

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
	EventBus.section_switched.connect(_on_section_changed)
	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.bpm_changed.connect(_on_bpm_changed)
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.track_selected.connect(func(track: int): selected_track_index = track)
	EventBus.recording_started.connect(func(): is_recording = true)
	EventBus.recording_stopped.connect(func(_audio): is_recording = false)



func _on_bpm_changed(new_bpm: int) -> void:
	bpm = new_bpm
	
# ── Section helpers ──────────────────────────────────────────────────────────

func _on_section_changed(section: SectionData) -> void:
	current_section = section

# ── Convenience accessors ────────────────────────────────────────────────────


func is_beat_active(track: int, beat: int) -> bool:
	if current_section:
		return current_section.get_beat(track, beat)
	return false

func has_active_beats_on_section(section_index: int) -> bool:
	return sections[section_index].has_active_beats()

func is_last_section() -> bool:
	return current_section_index == sections.size() - 1
