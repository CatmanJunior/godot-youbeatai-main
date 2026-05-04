class_name SectionData
extends Resource

## Data class representing a single section (formerly "layer").
## Contains sample tracks, synth tracks, and the button tex.
## Extends Resource so the entire section (including audio recordings) is serializable.

const SAMPLE_TRACKS_PER_SECTION: int = 4
const SYNTH_TRACKS_PER_SECTION: int = 2
const TRACKS_PER_SECTION: int = SAMPLE_TRACKS_PER_SECTION + SYNTH_TRACKS_PER_SECTION

static var last_id: int = 0
static func get_next_id() -> int:
	last_id += 1
	return last_id

var id: int
@export var index: int

## Combined array of sample and synth tracks 
@export var tracks: Array[TrackData] = []

## Emoji shown on the section button
@export var tex: Texture2D

@export var progression: ChordProgression
@export var progression_offset: ProgressionOffset

@export var loop_count: int = 1

# ── Initialization ───────────────────────────────────────────────────────────
## Initialize with a new unique ID. Tracks are NOT created here to avoid
## ghost sub-resources that corrupt Godot's typed-array serialization.
## Call [method create_default_tracks] explicitly when creating a brand-new section.
func _init(section_tex: Texture2D, new_index: int = 0) -> void:
	self.id = get_next_id()
	self.index = new_index
	tex = section_tex

## Populate [member tracks] with the default set of [SampleTrackData] and
## [SynthTrackData] instances. Must be called explicitly after constructing a
## new section; it is intentionally NOT called from [method _init] so that
## Godot's ResourceSaver does not encounter ghost sub-resources during
## serialization.
func create_default_tracks() -> void:
	for i in range(SAMPLE_TRACKS_PER_SECTION):
		tracks.append(SampleTrackData.new(i, index))
	for i in range(SYNTH_TRACKS_PER_SECTION):
		tracks.append(SynthTrackData.new(i + SAMPLE_TRACKS_PER_SECTION, index))
	
# ── Post-load rebuild ────────────────────────────────────────────────────────

## Call after loading from disk to restore runtime-only state (Sequence, id, etc.).
func rebuild_runtime() -> void:
	self.id = get_next_id()
	for track in tracks:
		if track is SynthTrackData:
			track.rebuild_sequence()
		# Rebuild RecordingData from saved audio streams
		if track.recorded_audio_stream is AudioStreamWAV:
			track.recording_data = RecordingData.new(track, track.recorded_audio_stream as AudioStreamWAV)
			track.recording_data.state = RecordingData.State.RECORDING_DONE

# ── Beat access helpers ──────────────────────────────────────────────────────

## Get a [ track ][ beat ] bool array for compatibility with UI and beat manager.
func get_beat_actives() -> Array:
	var result: Array = []
	for track in tracks:
		if track is SampleTrackData:
			result.append(track.beats)
	return result

## Set beats from a [ track ][ beat ] bool array.
func set_beat_actives(beat_actives: Array) -> void:
	for track_index in SAMPLE_TRACKS_PER_SECTION:
		var track_beats = beat_actives[track_index]
		for beat_index in range(track_beats.size()):
			set_beat(track_index, beat_index, track_beats[beat_index])

## Toggle a beat on/off by index.
func toggle_beat(track: int, beat: int):
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION:
		set_beat(track, beat, not get_beat(track, beat))

## Set a beat active/inactive by index.
func set_beat(track: int, beat: int, active: bool):
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION and beat >= 0 and beat < tracks[track].beats.size():
		tracks[track].beats[beat] = active

## Check if any beats are active on any sample track.
func get_beat(track: int, beat: int) -> bool:
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION and beat >= 0 and beat < tracks[track].beats.size():
		return tracks[track].beats[beat]
	return false
	
## Check if any beats are active on any sample track.
func has_active_beats() -> bool:
	for track in tracks:
		if track is SampleTrackData and track.has_active_beats():
			return true
	return false

## Clear all beats on all sample tracks.
func clear_beats() -> void:
	for track in tracks:
		if track is SampleTrackData:
			track.clear_beats()


# ── Knob helpers ─────────────────────────────────────────────────────────────

func get_track_knob_position(track_index: int) -> Vector2:
	if track_index == SongTrackData.SONG_TRACK_INDEX:
		return SongState.song_track.knob_position

	if track_index >= 0 and track_index < TRACKS_PER_SECTION:
		return tracks[track_index].knob_position
	return Vector2.ZERO

func get_section_knob_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for track in tracks:
		positions.append(track.knob_position)
	return positions

func set_section_knob_positions(positions: Array[Vector2]) -> void:
	for i in range(positions.size()):
		set_track_knob_position(i, positions[i])

func set_track_knob_position(track_index: int, position: Vector2) -> void:
	if track_index >= 0 and track_index < TRACKS_PER_SECTION:
		tracks[track_index].knob_position = position


# ── Duplicate ────────────────────────────────────────────────────────────────

func duplicate_section() -> SectionData:
	var copy: SectionData = SectionData.new(tex, index)

	for i in range(tracks.size()):
		var track_copy = tracks[i].duplicate_track()
		copy.tracks.append(track_copy)

	return copy
