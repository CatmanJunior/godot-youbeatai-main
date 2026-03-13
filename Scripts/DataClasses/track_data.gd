class_name TrackData
extends RefCounted

## Base data class for a single track within a section.
## Contains chaos pad knob position, mixing state, and audio player references.

## Chaos pad knob position for mixing on this track
var knob_position: Vector2 = Vector2.ZERO

## Current mixing state for this track
var master_volume: float = 0.0
var weights: Vector3 = Vector3.ZERO

## Audio player references (set at runtime by AudioPlayerManager)
var audio_player: AudioStreamPlayer = null
var sync_stream: AudioStreamSynchronized = null


func _init(default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	knob_position = default_knob_pos


func duplicate_track() -> TrackData:
	var copy := TrackData.new(knob_position)
	copy.master_volume = master_volume
	copy.weights = weights
	return copy
