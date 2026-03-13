class_name TrackData
extends RefCounted


enum TrackType { SAMPLE, SYNTH }

var track_type: TrackType = TrackType.SAMPLE

## Base data class for a single track within a section.
## Contains chaos pad knob position, mixing state, and audio player references.

var recorded_audio_stream: AudioStream = null

## Chaos pad knob position for mixing on this track
var knob_position: Vector2 = Vector2.ZERO

## Current mixing state for this track
var master_volume: float = 0.0
var weights: Vector3 = Vector3.ZERO

## Audio player references (set at runtime by AudioPlayerManager)
var audio_player: AudioStreamPlayer = null
var sync_stream: AudioStreamSynchronized = null


func _init(default_knob_pos: Vector2 = Vector2.ZERO, type: TrackType = TrackType.SAMPLE) -> void:
	knob_position = default_knob_pos
	self.track_type = type


func duplicate_track() -> TrackData:
	var copy : TrackData = TrackData.new(knob_position, track_type)
	copy.master_volume = master_volume
	copy.weights = weights
	copy.recorded_audio_stream = recorded_audio_stream
	return copy

func set_recording_audio_stream(audio_stream: AudioStream) -> void:
	recorded_audio_stream = audio_stream
