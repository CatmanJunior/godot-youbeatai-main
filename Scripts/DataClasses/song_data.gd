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

const DEFAULT_BPM: int = 120
const DEFAULT_BEATS_PER_SECTION: int = 16
const DEFAULT_SWING: float = 0.05

## Bump when the saved layout changes and add a step to [method migrate].
const FORMAT_VERSION: int = 2
## Saves made before [member format_version] existed load with this value.
const LEGACY_FORMAT_VERSION: int = 1

const ERROR_NEWER_VERSION: String = "Dit liedje is gemaakt met een nieuwere versie van Ritme Robot. Update het spel om het te openen."
const ERROR_INVALID: String = "Dit bestand is geen geldig Ritme Robot liedje."


# ── Playback ─────────────────────────────────────────────────────────────────

@export var bpm: int = DEFAULT_BPM
@export var beats_per_section: int = DEFAULT_BEATS_PER_SECTION
@export var swing: float = DEFAULT_SWING

# ── Sections & song track ─────────────────────────────────────────────────────
@export var song_track: SongTrackData = null

## Full section resources — each contains its tracks, beats, knob positions, and recordings.
@export var sections: Array[SectionData] = []

## Index of the active section when saved.
@export var current_section_index: int = 0

# ── Soundbank ────────────────────────────────────────────────────────────────

@export var soundbank_name: String = ""
@export var soundbank: SoundBank

# ── Metadata ─────────────────────────────────────────────────────────────────

@export var title: String = ""
@export var created_at: String = ""
## Game version (project config/version) that wrote the file.
@export var version: String = "1.0"
@export var format_version: int = LEGACY_FORMAT_VERSION
@export var chosen_emoij: String = ""


# ══════════════════════════════════════════════════════════════════════════════
# Snapshot: capture live state → SongData
# ══════════════════════════════════════════════════════════════════════════════

## Create a deep-copy snapshot of the current live [SongData] for safe
## serialization.  Sections and song_track are duplicated so that saving
## does not mutate the running state.
static func from_current() -> SongData:
	var song := SongData.new()
	var live := SongState.data

	# Deep-copy mutable resources.
	# Build the sections array into a local variable first, then assign it in
	# one shot.  Appending directly to song.sections one-by-one can leave the
	# first element orphaned in the .tres file due to a Godot ResourceSaver
	# quirk with typed arrays that are mutated after construction.
	if live.song_track:
		song.song_track = live.song_track.duplicate_track() as SongTrackData
	var sections_snapshot: Array[SectionData] = []
	for section: SectionData in live.sections:
		sections_snapshot.append(section.duplicate_section())
	song.sections = sections_snapshot

	# Copy value-type fields from the live data
	song.bpm = live.bpm
	song.beats_per_section = live.beats_per_section
	song.swing = live.swing
	song.current_section_index = SongState.current_section_index

	# State originating outside SongData
	# The active bank lives in SongState.selected_soundbank; live.soundbank is only set by a load.
	song.soundbank = SongState.selected_soundbank if SongState.selected_soundbank else live.soundbank
	song.soundbank_name = live.soundbank_name
	if song.soundbank and song.soundbank_name.is_empty():
		song.soundbank_name = song.soundbank.resource_path.get_file().get_basename()
	song.title = live.title
	song.chosen_emoij = SongState.chosen_emoij
	song.created_at = Time.get_datetime_string_from_system(true)
	song.version = str(ProjectSettings.get_setting("application/config/version", ""))
	song.format_version = FORMAT_VERSION

	return song


# ══════════════════════════════════════════════════════════════════════════════
# Restore: SongData → live state
# ══════════════════════════════════════════════════════════════════════════════

## Push every field of this [SongData] into the live [member SongState.data]
## and emit the necessary signals so that managers and UI update.
func apply_to_current() -> void:
	# Stop playback so the beat clock does not tick during data replacement.
	EventBus.playing_change_requested.emit(false)

	# Null current_section immediately so that track_data returns null (instead of
	# a stale section that may have wrong track types) for the entire rebuild window.
	SongState.current_section = null

	# Emit the soundbank first: BeatManager copies the bank's bpm/swing on
	# soundbank_loaded, so the saved values must be applied after it.
	if soundbank:
		SoundBankLoader._patch_note_player_settings(soundbank)
		EventBus.soundbank_loaded.emit(soundbank)

	# Playback settings (via signals so BeatManager picks them up)
	EventBus.bpm_set_requested.emit(bpm)
	EventBus.swing_set_requested.emit(swing)

	# BeatManager has its own swing var and does NOT echo back to SongState,
	# so we also write directly to keep data in sync.
	SongState.bpm = bpm
	SongState.beats_per_section = beats_per_section
	SongState.swing = swing

	# Restore song track
	if song_track:
		SongState.song_track = song_track
		SongState.song_track.rebuild_runtime()
	else:
		SongState.song_track = SongTrackData.new()
	SongState.chords_active = SongState.song_track.knob_position != TrackData.KNOB_POSITION_UNSET

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
	SongState.data.soundbank = soundbank
	SongState.data.soundbank_name = soundbank_name
	SongState.data.title = title
	SongState.data.created_at = created_at
	SongState.data.version = version
	SongState.data.format_version = format_version
	SongState.chosen_emoij = chosen_emoij if not chosen_emoij.is_empty() else SongState.CHOSEN_EMOIJ_DEFAULT
	SongState.data.chosen_emoij = SongState.chosen_emoij

	# Notify listeners (SectionUI, TrackWaveformVisualizer) to rebuild runtime objects
	# before the section_switch_requested signal triggers the full UI cascade below.
	EventBus.song_loaded.emit()

	for section: SectionData in SongState.sections:
		EventBus.on_set_loop_count.emit(section.index, section.loop_count)

	# Switch to saved section
	if current_section_index >= 0 and current_section_index < SongState.sections.size():
		EventBus.section_switch_requested.emit(current_section_index)


# ══════════════════════════════════════════════════════════════════════════════
# Versioning
# ══════════════════════════════════════════════════════════════════════════════

## Returns a player-facing (Dutch) error message, or an empty string when the
## loaded data can safely be applied.
func validate() -> String:
	if format_version > FORMAT_VERSION:
		return ERROR_NEWER_VERSION
	if sections.is_empty() or bpm <= 0 or beats_per_section <= 0:
		return ERROR_INVALID
	for section: SectionData in sections:
		if section == null or section.tracks.size() != SectionData.TRACKS_PER_SECTION:
			return ERROR_INVALID
		for i in range(section.tracks.size()):
			var track: TrackData = section.tracks[i]
			if i < SectionData.SAMPLE_TRACKS_PER_SECTION:
				if not track is SampleTrackData:
					return ERROR_INVALID
			elif not track is SynthTrackData:
				return ERROR_INVALID
	return ""


## Upgrade data from older format versions to [constant FORMAT_VERSION].
## Call after [method validate] succeeded.
func migrate() -> void:
	# Version 1 did not store loop counts or chord progressions; the defaults are used.
	for section: SectionData in sections:
		section.loop_count = clampi(section.loop_count, 1, SectionData.LOOP_COUNT_MAX)
		for track: TrackData in section.tracks:
			if track is SampleTrackData:
				(track as SampleTrackData).beats.resize(beats_per_section)
	if current_section_index < 0 or current_section_index >= sections.size():
		current_section_index = 0
	format_version = FORMAT_VERSION


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
	# CACHE_MODE_IGNORE: always deserialize fresh from disk so the loaded objects
	# are never shared with objects already in the live SongState (which would
	# cause type corruption on a second load).
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res is SongData:
		return res as SongData
	push_error("SongData: loaded resource is not SongData: %s" % path)
	return null
