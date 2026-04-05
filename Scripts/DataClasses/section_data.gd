class_name SectionData
extends RefCounted

## Data class representing a single section (formerly "layer").
## Contains sample tracks, synth tracks, and the button emoji.

const SAMPLE_TRACKS_PER_SECTION: int = 4
const SYNTH_TRACKS_PER_SECTION: int = 2
const TRACKS_PER_SECTION: int = SAMPLE_TRACKS_PER_SECTION + SYNTH_TRACKS_PER_SECTION

static var last_id: int = 0
static func get_next_id() -> int:
	last_id += 1
	return last_id

var id: int
var index: int

## Combined array of sample and synth tracks 
var tracks: Array[TrackData] = []

## Emoji shown on the section button
var emoji: String = ""


## ── Initialization ───────────────────────────────────────────────────────────
func _init(new_index: int = 0, section_emoji: String = "") -> void:
	self.id = get_next_id()
	self.index = new_index

	emoji = section_emoji

	for i in range(SAMPLE_TRACKS_PER_SECTION):
		tracks.append(SampleTrackData.new(i))

	for i in range(SYNTH_TRACKS_PER_SECTION):
		tracks.append(SynthTrackData.new(i + SAMPLE_TRACKS_PER_SECTION))
	
	EventBus.template_set.connect(_on_template_set)


func _on_template_set(actives: Array[Array]) -> void:
	set_beat_actives(actives)

# ── Beat access helpers ──────────────────────────────────────────────────────

func get_beat_actives() -> Array:
	"""Return the [track][beat] bool array for compatibility."""
	var result: Array = []
	for track in tracks:
		if track is SampleTrackData:
			result.append(track.beats)
	return result

func set_beat_actives(beat_actives: Array) -> void:
	"""Set beats from a [track][beat] bool array."""
	for track_index in SAMPLE_TRACKS_PER_SECTION:
		var track_beats = beat_actives[track_index]
		for beat_index in range(track_beats.size()):
			set_beat(track_index, beat_index, track_beats[beat_index])

func toggle_beat(track: int, beat: int):
	"""Toggle a beat on or off for this section."""
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION:
		set_beat(track, beat, not get_beat(track, beat))

func set_beat(track: int, beat: int, active: bool):
	"""Set a beat to active or inactive for this section."""
	if track >= 0 and track < SAMPLE_TRACKS_PER_SECTION:
		tracks[track].beats[beat] = active

func get_beat(track: int, beat: int) -> bool:
	"""Get whether a beat is active for this section."""
	return tracks[track].beats[beat]

func has_active_beats() -> bool:
	for track in tracks:
		if track is SampleTrackData and track.has_active_beats():
			return true
	return false

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
		var track = tracks[i]
		if track is SampleTrackData:
			var track_copy : SampleTrackData = track.duplicate_track()
			copy.tracks[i] = track_copy
		elif track is SynthTrackData:
			var track_copy : SynthTrackData = track.duplicate_track()
			copy.tracks[i] = track_copy

	return copy
