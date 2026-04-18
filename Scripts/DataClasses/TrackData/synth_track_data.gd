class_name SynthTrackData
extends TrackData

## Data class for a synth-based track within a section.
## Holds voice-over recordings and note _sequence in addition to the base track properties.

## The note _sequence derived from voice analysis. Null if no recording processed yet.
## Sequence extends Node so we store its notes as a serializable array instead.
@export var sequence_notes: Array[SequenceNote] = []

var _sequence: Sequence = null

var synth_waveform_visualizer: SynthWaveform = null

func _init(track_index: int, p_section_index: int, knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(track_index, p_section_index, knob_pos, TrackType.SYNTH)


func rebuild_sequence() -> void:
	if sequence_notes.size() > 0:
		_sequence = Sequence.new(sequence_notes)
	else:
		_sequence = null


## Set a new _sequence and keep the serializable notes array in sync.
func set_sequence(new_sequence: Sequence) -> void:
	_sequence = new_sequence
	if new_sequence:
		sequence_notes = new_sequence.notes.duplicate()
	else:
		sequence_notes.clear()

func duplicate_track() -> TrackData:
	var copy := SynthTrackData.new(index, section_index, knob_position)
	copy.recorded_audio_stream = recorded_audio_stream
	copy.recording_data = recording_data.duplicate()
	copy.master_volume = master_volume
	copy.weights = weights
	copy.sequence_notes = sequence_notes.duplicate()
	copy._sequence = _sequence
	copy.synth_waveform_visualizer = synth_waveform_visualizer
	return copy
