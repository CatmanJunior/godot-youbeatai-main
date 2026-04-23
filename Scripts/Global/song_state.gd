extends Node
## Song state singleton (autoload).
## Acts as an adapter over a live [SongData] instance so that the
## serializable resource and the runtime state are always in sync.
##
## Persistent song properties (sections, tempo, song_track …) are delegated
## to [member data].  Runtime-only state (current_section pointer,
## selected_track_index, selected_soundbank) lives directly on this node.

const BEATS_AMOUNT_DEFAULT: int = 16

## The underlying serializable song data.
## All persistent song properties are read from / written to this instance.
var data: SongData = SongData.new()

# ── Delegated properties (read/write through data) ──────────────────────────

var song_track: SongTrackData:
	get: return data.song_track
	set(value): data.song_track = value

var sections: Array[SectionData]:
	get: return data.sections
	set(value): data.sections = value

var bpm: int:
	get: return data.bpm
	set(value): data.bpm = value

var total_beats: int:
	get: return data.total_beats
	set(value): data.total_beats = value

var swing: float:
	get: return data.swing
	set(value): data.swing = value

# ── Runtime-only state ──────────────────────────────────────────────────────

var current_section: SectionData = null

var current_section_index: int:
	get:
		if current_section:
			return current_section.index
		else:
			return 0

var selected_track_index: int = 0

var current_track: TrackData:
	get:
		if selected_track_index == SongTrackData.SONG_TRACK_INDEX:
			return song_track
		if current_section and selected_track_index >= 0 and selected_track_index < current_section.tracks.size():
			return current_section.tracks[selected_track_index]
		return null

var selected_soundbank: AudioBank = null

# ── Initialization ───────────────────────────────────────────────────────────

func _ready() -> void:
	_apply_data_defaults()

	EventBus.section_switched.connect(_on_section_switched)
	EventBus.bpm_changed.connect(_on_bpm_changed)
	EventBus.track_selected.connect(func(track: int): selected_track_index = track)


## Ensure data has sensible runtime defaults (song_track, total_beats).
func _apply_data_defaults() -> void:
	if data.song_track == null:
		data.song_track = SongTrackData.new()
	if data.total_beats == 0:
		data.total_beats = BEATS_AMOUNT_DEFAULT


func _on_bpm_changed(new_bpm: int) -> void:
	data.bpm = new_bpm
	print("BPM changed to %d" % new_bpm)


func _on_section_switched(section: SectionData) -> void:
	current_section = section
	data.current_section_index = section.index if section else 0


# ── Helpers ──────────────────────────────────────────────────────────────────

func section_count() -> int:
	return data.sections.size()


func get_section(index: int) -> SectionData:
	if index >= 0 and index < data.sections.size():
		return data.sections[index]
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
	if section_index >= 0 and section_index < data.sections.size():
		return data.sections[section_index].has_active_beats()
	return false


func is_last_section() -> bool:
	return current_section_index == data.sections.size() - 1


# ── Reset ────────────────────────────────────────────────────────────────────

func reset() -> void:
	data = SongData.new()
	_apply_data_defaults()
	current_section = null
	selected_track_index = 0
	selected_soundbank = null
