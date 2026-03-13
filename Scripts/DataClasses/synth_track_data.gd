class_name SynthTrackData
extends TrackData

## Data class for a synth-based track within a section.
## Holds voice-over recordings in addition to the base track properties.

func _init(default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(default_knob_pos, TrackType.SYNTH)



func duplicate_track() -> TrackData:
	var copy : SynthTrackData = SynthTrackData.new(knob_position)
	copy.recorded_audio_stream = recorded_audio_stream
	copy.master_volume = master_volume
	copy.weights = weights
	return copy
