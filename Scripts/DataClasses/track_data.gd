class_name TrackData
extends RefCounted


enum TrackType { SAMPLE, SYNTH }

var track_type: TrackType = TrackType.SAMPLE

var index: int = -1 

## Base data class for a single track within a section.
## Contains chaos pad knob position, mixing state, and audio player references.

var recorded_audio_stream: AudioStream = null
var recording_data: RecordingData = null

## Chaos pad knob position for mixing on this track
var knob_position: Vector2 = Vector2.ZERO

## Current mixing state for this track
var master_volume: float = 0.0
var weights: Vector3 = Vector3.ZERO

## Audio player references (set at runtime by AudioPlayerManager)
var audio_player: AudioStreamPlayer = null
var sync_stream: AudioStreamSynchronized = null


func _init(track_index:int, knob_pos: Vector2 = Vector2.ZERO, type: TrackType = TrackType.SAMPLE) -> void:
	knob_position = knob_pos
	self.track_type = type
	self.index = track_index


func duplicate_track() -> TrackData:
	var copy : TrackData = TrackData.new(index, knob_position, track_type)
	copy.master_volume = master_volume
	copy.weights = weights
	copy.recorded_audio_stream = recorded_audio_stream
	copy.recording_data = recording_data
	return copy

func start_recording(p_section_index: int) -> RecordingData:
	recording_data = RecordingData.new(self, p_section_index)
	recording_data.state = RecordingData.State.RECORDING
	return recording_data

func set_recording_audio_stream(audio_stream: AudioStream) -> void:
	recorded_audio_stream = audio_stream
	if audio_stream is AudioStreamWAV:
		if recording_data != null:
			recording_data.audio_stream = audio_stream as AudioStreamWAV
			# Only advance to RECORDING_DONE if not already in PROCESSING state
			# (synth tracks stay in PROCESSING until voice analysis completes)
			if recording_data.state != RecordingData.State.PROCESSING:
				recording_data.state = RecordingData.State.RECORDING_DONE
		else:
			push_warning("RecordingData was null when set_recording_audio_stream was called — bypassing start_recording() flow.")
			recording_data = RecordingData.new(self, -1, audio_stream as AudioStreamWAV)
			recording_data.state = RecordingData.State.RECORDING_DONE
	else:
		recording_data = null

func has_recording() -> bool:
	return recording_data != null and recording_data.audio_stream != null
