class_name SynthTrackData
extends TrackData

## Data class for a synth-based track within a section.
## Holds voice-over recordings and note sequence in addition to the base track properties.

## The note sequence derived from voice analysis. Null if no recording processed yet.
## Sequence extends Node so we store its notes as a serializable array instead.
@export var sequence_notes: Array[SequenceNote] = []

var sequence: Sequence = null

var synth_waveform_visualizer: SynthWaveform = null

func _init(track_index: int = -1, p_section_index: int = -1, knob_pos: Vector2 = TrackData.KNOB_POSITION_UNSET) -> void:
	super._init(track_index, p_section_index, knob_pos, TrackType.SYNTH)


func rebuild_sequence() -> void:
	if sequence_notes.size() > 0:
		sequence = Sequence.new(sequence_notes)
	else:
		sequence = null


## Set a new sequence and keep the serializable notes array in sync.
func set_sequence(new_sequence: Sequence) -> void:
	sequence = new_sequence
	if new_sequence:
		sequence_notes = new_sequence.notes.duplicate()
	else:
		sequence_notes.clear()

func duplicate_track() -> TrackData:
	var copy := SynthTrackData.new(index, section_index, knob_position)
	if recorded_audio_stream:
		copy.recorded_audio_stream = recorded_audio_stream

	copy.master_volume = master_volume
	copy.weights = weights
	if sequence_notes:
		copy.sequence_notes = sequence_notes.duplicate()
	if sequence:
		copy.sequence = sequence
	if synth_waveform_visualizer:
		copy.synth_waveform_visualizer = synth_waveform_visualizer
	return copy
