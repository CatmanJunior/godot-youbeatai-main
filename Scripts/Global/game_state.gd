extends Node

## Global game state singleton (autoload).
## Provides easy access to sections, playback state, and common data
## without needing %UniqueNode references everywhere.

const BEATS_AMOUNT_DEFAULT: int = 16


# -- Settings --
var base_time_per_beat: float = 0.5

var microphone_volume: float = 0.0

var recording_delay_seconds: float = 0.0

var recording_volume_threshold: float = 0.1

var track_button_add_beats: bool = false

var button_is_clap: bool = false

var clap_bias: float = 0.0

var metronome_enabled: bool = false

var mute_speech: bool = false

# -- Sections --

var sections: Array[SectionData] = []
var current_section: SectionData = null
var current_section_index: int = 0

# -- Playback --
var playing: bool = false
var bpm: int = 120
var current_beat: int = 0
var beats_amount: int = 16
var swing: float = 0.05
var beat_progress: float = 0.0
var bar_progress: float = 0.0

var time_per_beat: float:
	get:
		return 60.0 / bpm

# -- Mixing --

var selected_sample_track: int = 0
var selected_synth_track: int = 0
var selected_track_index: int = 0
var selected_track: TrackData:
	get:
		if current_section and selected_track_index >= 0 and selected_track_index < current_section.tracks.size():
			return current_section.tracks[selected_track_index]
		return null

# -- Recording --

var is_recording: bool = false

func _ready() -> void:
	EventBus.section_changed.connect(_on_section_changed)

	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.bpm_changed.connect(_on_bpm_changed)
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.track_selected.connect(func(track: int): selected_track_index = track)
	EventBus.recording_started.connect(func(): is_recording = true)
	EventBus.recording_stopped.connect(func(_audio): is_recording = false)
	EventBus.recording_volume_threshold_changed.connect(_on_recording_volume_threshold_changed)

func _on_bpm_changed(new_bpm: int) -> void:
	bpm = new_bpm
	base_time_per_beat = 60.0 / bpm
	
func _on_recording_volume_threshold_changed(threshold: float) -> void:
	recording_volume_threshold = threshold

# ── Section helpers ──────────────────────────────────────────────────────────

func _on_section_changed(_old_section: SectionData, section: SectionData) -> void:
	current_section = section

# ── Convenience accessors ────────────────────────────────────────────────────

func get_section(index: int) -> SectionData:
	if index >= 0 and index < sections.size():
		return sections[index]
	return null

func get_current_track(track: int) -> SampleTrackData:
	return current_section.tracks[track]

func get_beat(track: int, beat: int) -> bool:
	if current_section:
		return current_section.get_beat(track, beat)
	return false

func has_active_beats_on_section(section_index: int) -> bool:
	var section = get_section(section_index)
	if section:
		return section.has_active_beats()
	return false

func is_last_section() -> bool:
	return current_section_index == sections.size() - 1
