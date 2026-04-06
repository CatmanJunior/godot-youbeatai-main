class_name SectionData
extends Resource

## Data class representing a single section (formerly "layer").
## Contains sample tracks, synth tracks, and the button emoji.
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
@export var emoji: String = ""


# ── Initialization ───────────────────────────────────────────────────────────
## Initialize with empty tracks and a new unique ID. Connect to template_set to update beats when a template is applied.
func _init(new_index: int = 0, section_emoji: String = "") -> void:
	self.id = get_next_id()
	self.index = new_index

	emoji = section_emoji
	if tracks.is_empty():
		for i in range(SAMPLE_TRACKS_PER_SECTION):
			tracks.append(SampleTrackData.new(i))

		for i in range(SYNTH_TRACKS_PER_SECTION):
			tracks.append(SynthTrackData.new(i + SAMPLE_TRACKS_PER_SECTION))
	
	EventBus.template_set.connect(_on_template_set)

# -- Event handlers ─────────────────────────────────────────────────────────────

func _on_template_set(actives: Array) -> void:
	if SongState.current_section_index == index:
		set_beat_actives(actives)

# ── Post-load rebuild ────────────────────────────────────────────────────────

## Call after loading from disk to restore runtime-only state (Sequence, id, etc.).
func rebuild_runtime() -> void:
	self.id = get_next_id()
	for track in tracks:
		if track is SynthTrackData:
			track.rebuild_sequence()
		# Rebuild RecordingData from saved audio streams
		if track.recorded_audio_stream is AudioStreamWAV:
			track.recording_data = RecordingData.new(track, index, track.recorded_audio_stream as AudioStreamWAV)
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
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION:
		tracks[track].beats[beat] = active

## Check if any beats are active on any sample track.
func get_beat(track: int, beat: int) -> bool:
	return tracks[track].beats[beat]

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
	var copy: SectionData = SectionData.new()

	for i in range(tracks.size()):
		var track_copy = tracks[i].duplicate_track()
		copy.tracks.append(track_copy)

	return copy
