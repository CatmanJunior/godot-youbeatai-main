class_name SectionData
extends RefCounted

## Data class representing a single section (formerly "layer").
## Contains sample tracks, synth tracks, and the button emoji.

const SAMPLE_TRACKS_PER_SECTION: int = 4
const SYNTH_TRACKS_PER_SECTION: int = 2
const TRACKS_PER_SECTION: int = SAMPLE_TRACKS_PER_SECTION + SYNTH_TRACKS_PER_SECTION

## The 4 sample tracks (stomp, clap, instrument 1, instrument 2)
var sample_tracks: Array[SampleTrackData] = []

## The 2 synth tracks (green / purple)
var synth_tracks: Array[SynthTrackData] = []

## Emoji shown on the section button
var emoji: String = ""

func _init(beats_amount: int = GameState.BEATS_AMOUNT_DEFAULT, default_knob_pos: Vector2 = Vector2.ZERO, section_emoji: String = "") -> void:
	emoji = section_emoji

	sample_tracks = []
	for i in range(SAMPLE_TRACKS_PER_SECTION):
		sample_tracks.append(SampleTrackData.new(beats_amount, default_knob_pos))

	synth_tracks = []
	for i in range(SYNTH_TRACKS_PER_SECTION):
		synth_tracks.append(SynthTrackData.new(default_knob_pos))


# ── Beat access helpers ──────────────────────────────────────────────────────

func get_beat_actives() -> Array:
	"""Return the [track][beat] bool array for compatibility."""
	var result: Array = []
	for track in sample_tracks:
		result.append(track.beats)
	return result


func set_beat_actives(beat_actives: Array) -> void:
	"""Set beats from a [track][beat] bool array."""
	for track_index in range(mini(beat_actives.size(), sample_tracks.size())):
		var track_beats = beat_actives[track_index]
		for beat_index in range(mini(track_beats.size(), sample_tracks[track_index].beats.size())):
			sample_tracks[track_index].beats[beat_index] = track_beats[beat_index]

func toggle_beat(track: int, beat: int):
	"""Toggle a beat on or off for this section."""
	if track >= 0 and track < sample_tracks.size():
		sample_tracks[track].beats[beat] = not sample_tracks[track].beats[beat]

func set_beat(track: int, beat: int, active: bool):
	"""Set a beat to active or inactive for this section."""
	if track >= 0 and track < sample_tracks.size():
		sample_tracks[track].beats[beat] = active

func get_beat(track: int, beat: int) -> bool:
	"""Get whether a beat is active for this section."""
	return sample_tracks[track].beats[beat]

func has_active_beats() -> bool:
	for track in sample_tracks:
		if track.has_active_beats():
			return true
	return false


func clear_beats() -> void:
	for track in sample_tracks:
		track.clear_beats()


# ── Knob helpers ─────────────────────────────────────────────────────────────

func get_sample_knob_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for track in sample_tracks:
		positions.append(track.knob_position)
	return positions

func get_synth_knob_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for track in synth_tracks:
		positions.append(track.knob_position)
	return positions

func get_sample_knob_position(track_index: int) -> Vector2:
	if track_index >= 0 and track_index < sample_tracks.size():
		return sample_tracks[track_index].knob_position
	return Vector2.ZERO

func get_synth_knob_position(synth_index: int) -> Vector2:
	if synth_index >= 0 and synth_index < synth_tracks.size():
		return synth_tracks[synth_index].knob_position
	return Vector2.ZERO

func set_knob_positions(positions: Array[Vector2]) -> void:
	for i in range(positions.size()):
		if i < SAMPLE_TRACKS_PER_SECTION:
			sample_tracks[i].knob_position = positions[i]
		else:
			synth_tracks[i - SAMPLE_TRACKS_PER_SECTION].knob_position = positions[i]

func set_sample_knob_position(track_index: int, position: Vector2) -> void:
	if track_index >= 0 and track_index < sample_tracks.size():
		sample_tracks[track_index].knob_position = position

func set_synth_knob_position(synth_index: int, position: Vector2) -> void:
	if synth_index >= 0 and synth_index < synth_tracks.size():
		synth_tracks[synth_index].knob_position = position


func set_sample_knob_positions(positions: Array[Vector2]) -> void:
	for i in range(mini(positions.size(), sample_tracks.size())):
		sample_tracks[i].knob_position = positions[i]


# ── Duplicate ────────────────────────────────────────────────────────────────

func duplicate_section() -> SectionData:
	var copy := SectionData.new(
		sample_tracks[0].beats.size() if sample_tracks.size() > 0 else GameState.BEATS_AMOUNT_DEFAULT,
		Vector2.ZERO,
		emoji
	)
	for i in range(sample_tracks.size()):
		copy.sample_tracks[i] = sample_tracks[i].duplicate_track() as SampleTrackData

	for i in range(SYNTH_TRACKS_PER_SECTION):
		copy.synth_tracks[i] = synth_tracks[i].duplicate_track() as SynthTrackData

	return copy
