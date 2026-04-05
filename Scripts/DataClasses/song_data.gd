class_name SongData
extends Resource

## Top-level resource containing the full song state.
## Because SectionData → TrackData → AudioStreamWAV are all Resources,
## Godot serializes the entire tree — including recorded samples.
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

static func from_current() -> SongData:
	var song := SongData.new()
	if GameState.song_track:
		song.song_track = GameState.song_track.duplicate_track() as SongTrackData
	song.bpm = GameState.bpm
	song.total_beats = GameState.total_beats
	song.swing = GameState.swing
	song.playing = GameState.playing
	song.current_section_index = GameState.current_section_index
	song.audio_bank = SoundBankLoader.load_audio_bank(GameState.selected_soundbank)
	song.created_at = Time.get_datetime_string_from_system(true)

	# Sections are already Resources — duplicate so saving doesn't mutate live state
	for section: SectionData in GameState.sections:
		song.sections.append(section.duplicate_section())

	return song


# ══════════════════════════════════════════════════════════════════════════════
# Restore: SongData → live state
# ══════════════════════════════════════════════════════════════════════════════

func apply_to_current() -> void:
	# Playback settings
	EventBus.bpm_set_requested.emit(bpm)
	EventBus.swing_set_requested.emit(swing)
	GameState.total_beats = total_beats
	# Restore song track
	if song_track:
		GameState.song_track = song_track
		GameState.song_track.rebuild_runtime()
	else:
		GameState.song_track = SongTrackData.new()
	# Rebuild sections
	GameState.sections.clear()
	for i in range(sections.size()):
		var section: SectionData = sections[i]
		section.index = i
		section.rebuild_runtime()
		GameState.sections.append(section)

	# Switch to saved section
	if current_section_index >= 0 and current_section_index < GameState.sections.size():
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
