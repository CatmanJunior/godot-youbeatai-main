class_name SynthData
extends RefCounted

## Data class for a single synth within a layer.
## Each synth holds its chaos pad knob position, voice-over recordings, and mixing state.

## Chaos pad knob position for synth mixing
var synth_knob_position: Vector2 = Vector2.ZERO

## Voice-over recording for this synth voice
var voice_over: AudioStream = null

## Per-synth layer voice-over recording (recorded via LayerVoiceOver nodes)
var layer_voice_over: AudioStream = null

## Current mixing state for this synth
var master_volume: float = 0.0
var weights: Vector3 = Vector3.ZERO


func _init(default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	synth_knob_position = default_knob_pos


func duplicate_synth() -> SynthData:
	var copy := SynthData.new(synth_knob_position)
	copy.voice_over = voice_over
	copy.layer_voice_over = layer_voice_over
	copy.master_volume = master_volume
	copy.weights = weights
	return copy
