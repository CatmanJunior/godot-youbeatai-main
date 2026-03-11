class_name LayerData
extends RefCounted

## Data class representing a single layer.
## Contains rings, voice-over recordings, synth knob positions, and the button emoji.

const RINGS_PER_LAYER: int = 4
const SYNTHS_PER_LAYER: int = 2

## The 4 rings that make up this layer (stomp, clap, instrument 1, instrument 2)
var rings: Array[RingData] = []

## The 2 synths that make up this layer (green / purple)
var synths: Array[SynthData] = []

## Emoji shown on the layer button
var emoji: String = ""

func _init(beats_amount: int = RingData.BEATS_AMOUNT_DEFAULT, default_knob_pos: Vector2 = Vector2.ZERO, layer_emoji: String = "") -> void:
	emoji = layer_emoji

	rings = []
	for i in range(RINGS_PER_LAYER):
		rings.append(RingData.new(beats_amount, default_knob_pos))

	synths = []
	for i in range(SYNTHS_PER_LAYER):
		synths.append(SynthData.new(default_knob_pos))


# ── Beat access helpers ──────────────────────────────────────────────────────

func get_beat_actives() -> Array:
	"""Return the legacy [ring][beat] bool array for compatibility."""
	var result: Array = []
	for ring in rings:
		result.append(ring.beats)
	return result


func set_beat_actives(beat_actives: Array) -> void:
	"""Set beats from a legacy [ring][beat] bool array."""
	for ring_index in range(mini(beat_actives.size(), rings.size())):
		var ring_beats = beat_actives[ring_index]
		for beat_index in range(mini(ring_beats.size(), rings[ring_index].beats.size())):
			rings[ring_index].beats[beat_index] = ring_beats[beat_index]

func toggle_beat(ring: int, beat: int):
	"""Toggle a beat on or off for this layer."""
	if ring >= 0 and ring < rings.size():
		rings[ring].beats[beat] = not rings[ring].beats[beat]

func set_beat(ring: int, beat: int, active: bool):
	"""Set a beat to active or inactive for this layer."""
	if ring >= 0 and ring < rings.size():
		rings[ring].beats[beat] = active

func get_beat(ring: int, beat: int) -> bool:
	"""Get whether a beat is active for this layer."""
	return rings[ring].beats[beat]

func has_active_beats() -> bool:
	for ring in rings:
		if ring.has_active_beats():
			return true
	return false


func clear_beats() -> void:
	for ring in rings:
		ring.clear_beats()


# ── Knob helpers ─────────────────────────────────────────────────────────────

func get_sample_knob_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for ring in rings:
		positions.append(ring.sample_knob_position)
	return positions

func get_synth_knob_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for synth in synths:
		positions.append(synth.synth_knob_position)
	return positions

func get_sample_knob_position(ring_index: int) -> Vector2:
	if ring_index >= 0 and ring_index < rings.size():
		return rings[ring_index].sample_knob_position
	return Vector2.ZERO

func get_synth_knob_position(synth_index: int) -> Vector2:
	if synth_index >= 0 and synth_index < synths.size():
		return synths[synth_index].synth_knob_position
	return Vector2.ZERO

func set_knob_positions(positions: Array[Vector2]) -> void:
	for i in range(positions.size()):
		if i < RINGS_PER_LAYER:
			rings[i].sample_knob_position = positions[i]
		else:
			synths[i - RINGS_PER_LAYER].synth_knob_position = positions[i]

func set_sample_knob_position(ring_index: int, position: Vector2) -> void:
	if ring_index >= 0 and ring_index < rings.size():
		rings[ring_index].sample_knob_position = position

func set_synth_knob_position(synth_index: int, position: Vector2) -> void:
	if synth_index >= 0 and synth_index < synths.size():
		synths[synth_index].synth_knob_position = position



# ── Duplicate ────────────────────────────────────────────────────────────────

func duplicate_layer() -> LayerData:
	var copy := LayerData.new(
		rings[0].beats.size() if rings.size() > 0 else RingData.BEATS_AMOUNT_DEFAULT,
		Vector2.ZERO,
		emoji
	)
	for i in range(rings.size()):
		copy.rings[i] = rings[i].duplicate_ring()

	for i in range(SYNTHS_PER_LAYER):
		copy.synths[i] = synths[i].duplicate_synth()

	return copy
