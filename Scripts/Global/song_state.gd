extends Node

## Song state singleton (autoload).
## Provides access to song-related data: sections, tracks, soundbank, and tempo.
## Wraps SongData so the live state and the serializable resource stay in sync.

const BEATS_AMOUNT_DEFAULT: int = 16

# ── Song Track ───────────────────────────────────────────────────────────────

var song_track: SongTrackData = SongTrackData.new()

# ── Sections & Tracks ────────────────────────────────────────────────────────

var sections: Array[SectionData] = []
var current_section: SectionData = null

var current_section_index: int:
	get:
		if current_section:
			return current_section.index
		else:
			return -1

var selected_track_index: int = 0

var current_track: TrackData:
	get:
		if current_section and selected_track_index >= 0 and selected_track_index < current_section.tracks.size():
			return current_section.tracks[selected_track_index]
		return null

# ── Soundbank ────────────────────────────────────────────────────────────────

var selected_soundbank: Dictionary = {}

# ── Tempo ────────────────────────────────────────────────────────────────────

var bpm: int = 120
var total_beats: int = BEATS_AMOUNT_DEFAULT
var swing: float = 0.05


# ── Initialization ───────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.section_switched.connect(_on_section_changed)
	EventBus.bpm_changed.connect(_on_bpm_changed)
	EventBus.track_selected.connect(func(track: int): selected_track_index = track)


func _on_bpm_changed(new_bpm: int) -> void:
	bpm = new_bpm


func _on_section_changed(section: SectionData) -> void:
	current_section = section


# ── Helpers ──────────────────────────────────────────────────────────────────

func section_count() -> int:
	return sections.size()


func get_section(index: int) -> SectionData:
	if index >= 0 and index < sections.size():
		return sections[index]
	return null


func get_track(section_index: int, track_index: int) -> TrackData:
	var section := get_section(section_index)
	if section and track_index >= 0 and track_index < section.tracks.size():
		return section.tracks[track_index]
	return null


func is_beat_active(track: int, beat: int) -> bool:
	if current_section:
		return current_section.get_beat(track, beat)
	return false


func has_active_beats_on_section(section_index: int) -> bool:
	if section_index >= 0 and section_index < sections.size():
		return sections[section_index].has_active_beats()
	return false


func is_last_section() -> bool:
	return current_section_index == sections.size() - 1


# ── Reset ────────────────────────────────────────────────────────────────────

func reset() -> void:
	song_track.clear()
	sections.clear()
	current_section = null
	selected_track_index = 0
	selected_soundbank = {}
	bpm = 120
	total_beats = BEATS_AMOUNT_DEFAULT
	swing = 0.05
