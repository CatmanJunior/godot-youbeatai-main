class_name SongData
extends Resource

## Top-level resource containing the full song state.
## Because SectionData → TrackData → AudioStreamWAV are all Resources,
## Godot serializes the entire tree — including recorded samples.
##
## At runtime [SongState] holds a live [SongData] instance and delegates all
## persistent song properties to it.  Use [method from_current] to create a
## deep-copy snapshot for saving, and [method apply_to_current] to restore a
## loaded snapshot into the live state.
##
## Save:  ResourceSaver.save(song, "user://songs/my_song.tres")
## Load:  var song := SongData.load_from_file("user://songs/my_song.tres")
##        song.apply_to_current()

@export var song_track: SongTrackData = null

# ── Playback ─────────────────────────────────────────────────────────────────

@export var bpm: int = 120
@export var total_beats: int = 16
@export var swing: float = 0.05
@export var playing: bool = false

# ── Sections ─────────────────────────────────────────────────────────────────

## Full section resources — each contains its tracks, beats, knob positions, and recordings.
@export var sections: Array[SectionData] = []

## Index of the active section when saved.
@export var current_section_index: int = 0

# ── Soundbank ────────────────────────────────────────────────────────────────

@export var soundbank_name: String = ""
@export var audio_bank: AudioBank

# ── Metadata ─────────────────────────────────────────────────────────────────

@export var title: String = ""
@export var created_at: String = ""
@export var version: String = "1.0"


# ══════════════════════════════════════════════════════════════════════════════
# Snapshot: capture live state → SongData
# ══════════════════════════════════════════════════════════════════════════════

## Create a deep-copy snapshot of the current live [SongData] for safe
## serialization.  Sections and song_track are duplicated so that saving
## does not mutate the running state.
static func from_current() -> SongData:
	var song := SongData.new()
	var live := SongState.data

	# Deep-copy mutable resources
	if live.song_track:
		song.song_track = live.song_track.duplicate_track() as SongTrackData
	for section: SectionData in live.sections:
		song.sections.append(section.duplicate_section())

	# Copy value-type fields from the live data
	song.bpm = live.bpm
	song.total_beats = live.total_beats
	song.swing = live.swing
	song.current_section_index = SongState.current_section_index

	# State originating outside SongData
	song.playing = GameState.playing
	song.audio_bank = live.audio_bank
	song.soundbank_name = live.soundbank_name
	song.created_at = Time.get_datetime_string_from_system(true)

	return song


# ══════════════════════════════════════════════════════════════════════════════
# Restore: SongData → live state
# ══════════════════════════════════════════════════════════════════════════════

## Push every field of this [SongData] into the live [member SongState.data]
## and emit the necessary signals so that managers and UI update.
func apply_to_current() -> void:
	# Playback settings (via signals so BeatManager picks them up)
	EventBus.bpm_set_requested.emit(bpm)
	EventBus.swing_set_requested.emit(swing)

	# BeatManager has its own swing var and does NOT echo back to SongState,
	# so we also write directly to keep data in sync.
	SongState.total_beats = total_beats
	SongState.swing = swing

	# Restore song track
	if song_track:
		SongState.song_track = song_track
		SongState.song_track.rebuild_runtime()
	else:
		SongState.song_track = SongTrackData.new()

	# Rebuild sections into the live array (preserves existing references)
	SongState.sections.clear()
	for i in range(sections.size()):
		var section: SectionData = sections[i]
		section.index = i
		section.rebuild_runtime()
		SongState.sections.append(section)

	# Sync metadata fields that have no delegated SongState property.
	# Note: `self` is the loaded SongData, NOT `SongState.data` — these
	# copy from the loaded file into the live data instance.
	SongState.data.audio_bank = audio_bank
	SongState.data.soundbank_name = soundbank_name
	SongState.data.title = title
	SongState.data.created_at = created_at
	SongState.data.version = version
	SongState.data.playing = playing

	# Switch to saved section
	if current_section_index >= 0 and current_section_index < SongState.sections.size():
		EventBus.section_switch_requested.emit(current_section_index)

	# Restore soundbank
	if audio_bank:
		EventBus.audio_bank_loaded.emit(audio_bank)

	# Restore playback last
	if playing:
		EventBus.playing_change_requested.emit(true)


# ══════════════════════════════════════════════════════════════════════════════
# File I/O
# ══════════════════════════════════════════════════════════════════════════════

func save_to_file(path: String) -> Error:
	var err := ResourceSaver.save(self, path)
	if err != OK:
		push_error("SongData: failed to save to %s — error %d" % [path, err])
	return err


static func load_from_file(path: String) -> SongData:
	if not ResourceLoader.exists(path):
		push_error("SongData: file not found: %s" % path)
		return null
	var res := ResourceLoader.load(path)
	if res is SongData:
		return res as SongData
	push_error("SongData: loaded resource is not SongData: %s" % path)
	return null
