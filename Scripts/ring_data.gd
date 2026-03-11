class_name RingData
extends RefCounted

## Data class for a single ring within a layer.
## Each ring holds beat pattern state and its chaos pad knob position.

const BEATS_AMOUNT_DEFAULT: int = 16

## Beat activation pattern — one bool per beat
var beats: Array[bool] = []

## Chaos pad knob position for sample mixing on this ring
var sample_knob_position: Vector2 = Vector2.ZERO

## Current mixing state for this ring
var master_volume: float = 0.0
var weights: Vector3 = Vector3.ZERO


func _init(beats_amount: int = BEATS_AMOUNT_DEFAULT, default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	sample_knob_position = default_knob_pos
	beats = []
	for i in range(beats_amount):
		beats.append(false)


func has_active_beats() -> bool:
	for active in beats:
		if active:
			return true
	return false


func clear_beats() -> void:
	for i in range(beats.size()):
		beats[i] = false


func duplicate_ring() -> RingData:
	var copy := RingData.new(beats.size(), sample_knob_position)
	for i in range(beats.size()):
		copy.beats[i] = beats[i]
	copy.master_volume = master_volume
	copy.weights = weights
	return copy
 