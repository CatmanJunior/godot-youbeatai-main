extends Node

## Global game state singleton (autoload).
## Provides easy access to sections, playback state, and common data
## without needing %UniqueNode references everywhere.

const BEATS_AMOUNT_DEFAULT: int = 16

var microphone_volume: float = 0.0

var recording_delay_seconds: float = 0.0

# ── Sections ─────────────────────────────────────────────────────────────────

var sections: Array[SectionData] = []
var current_section: SectionData = null
var current_section_index: int = 0
var sections_amount: int = 0

# ── Playback ─────────────────────────────────────────────────────────────────

var playing: bool = false
var bpm: int = 120
var current_beat: int = 0
var beats_amount: int = 16
var swing: float = 0.05

# ── Mixing ───────────────────────────────────────────────────────────────────

var selected_sample_track: int = 0
var selected_synth_track: int = 0

# ── Recording ────────────────────────────────────────────────────────────────

var is_recording: bool = false

func _ready() -> void:
	EventBus.section_changed.connect(_on_section_changed)
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_removed.connect(_on_section_removed)
	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.bpm_changed.connect(func(value: float): bpm = int(value))
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.ring_selected.connect(func(ring: int): selected_sample_track = ring)
	EventBus.synth_selected.connect(func(synth: int): selected_synth_track = synth)
	EventBus.recording_started.connect(func(): is_recording = true)
	EventBus.recording_stopped.connect(func(_audio): is_recording = false)


# ── Section helpers ──────────────────────────────────────────────────────────

func _on_section_changed(section: SectionData) -> void:
	current_section = section

func _on_section_added(section_index: int, _emoji: String) -> void:
	_sync_sections()

func _on_section_removed(_section_index: int) -> void:
	_sync_sections()

func _sync_sections() -> void:
	var sm = _get_section_manager()
	if sm:
		sections = sm.sections
		sections_amount = sm.sections_amount
		current_section_index = sm.current_section_index
		current_section = sm.current_section

func _get_section_manager():
	var tree = get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get_node_or_null("%LayerManager")


# ── Convenience accessors ────────────────────────────────────────────────────

func get_section(index: int) -> SectionData:
	if index >= 0 and index < sections.size():
		return sections[index]
	return null

func get_current_sample_track(track: int) -> SampleTrackData:
	if current_section and track >= 0 and track < current_section.sample_tracks.size():
		return current_section.sample_tracks[track]
	return null

func get_current_synth_track(synth: int) -> SynthTrackData:
	if current_section and synth >= 0 and synth < current_section.synth_tracks.size():
		return current_section.synth_tracks[synth]
	return null

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
	return current_section_index == sections_amount - 1
