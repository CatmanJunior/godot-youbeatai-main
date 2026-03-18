extends Node

## Global game state singleton (autoload).
## Provides easy access to sections, playback state, and common data
## without needing %UniqueNode references everywhere.

const BEATS_AMOUNT_DEFAULT: int = 16


# -- Settings --

var microphone_volume: float = 0.0

var recording_delay_seconds: float = 0.0

var recording_volume_threshold: float = 0.1

var track_button_add_beats: bool = false

var button_is_clap: bool = false

var clap_bias: float = 0.0

var metronome_enabled: bool = false

var mute_speech: bool = false

# -- Sections & Tracks --

var sections: Array[SectionData] = []
var current_section: SectionData = null
var current_section_index: int:
	get:
		return current_section.index

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

## time per quarter note in seconds, calculated from bpm
var time_per_beat: float:
	get:
		return 60.0 / bpm


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

func _on_section_changed(_old_section: SectionData, section: SectionData) -> void:
	current_section = section

# ── Convenience accessors ────────────────────────────────────────────────────


func get_beat(track: int, beat: int) -> bool:
	if current_section:
		return current_section.get_beat(track, beat)
	return false

func has_active_beats_on_section(section_index: int) -> bool:
	return sections[section_index].has_active_beats()

func is_last_section() -> bool:
	return current_section_index == sections.size() - 1
