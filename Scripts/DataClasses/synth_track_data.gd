class_name SynthTrackData
extends TrackData

## Data class for a synth-based track within a section.
## Holds voice-over recordings in addition to the base track properties.

## Voice-over recording for this synth voice
var voice_over: AudioStream = null

## Per-synth section voice-over recording (recorded via LayerVoiceOver nodes)
var layer_voice_over: AudioStream = null


func _init(default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(default_knob_pos)


func duplicate_track() -> TrackData:
	var copy := SynthTrackData.new(knob_position)
	copy.voice_over = voice_over
	copy.layer_voice_over = layer_voice_over
	copy.master_volume = master_volume
	copy.weights = weights
	return copy
