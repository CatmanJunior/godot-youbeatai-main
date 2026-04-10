## Base data class for a single track within a section.
## Contains chaos pad knob position, mixing state, and audio player references.
## Extends Resource so the full track state (including recordings) can be saved/loaded.
class_name TrackData
extends Resource

enum TrackType { SAMPLE, SYNTH, SONG }


@export var track_type: TrackType = TrackType.SAMPLE

@export var index: int = -1

## Recorded audio from the microphone (AudioStreamWAV is a Resource — saved automatically).
@export var recorded_audio_stream: AudioStream = null

## Chaos pad knob position for mixing on this track.
@export var knob_position: Vector2 = Vector2(150,150)

## Current mixing state for this track.
@export var master_volume: float = 0.0
@export var weights: Vector3 = Vector3(0.3, 0.3, 0.4)

var recording_data: RecordingData = null

func _init(track_index:int, knob_pos: Vector2 = Vector2(150,150), type: TrackType = TrackType.SAMPLE) -> void:
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

## Creates a new RecordingData for this track. Does NOT set recording state —
## the caller (track player) is responsible for managing state transitions.
func create_recording_data(p_section_index: int) -> RecordingData:
	recording_data = RecordingData.new(self, p_section_index)
	return recording_data

## Stores the recorded audio stream on this track and links it to the RecordingData.
## Does NOT manage recording state — the caller is responsible for state transitions.
func set_recording_audio_stream(audio_stream: AudioStream) -> void:
	recorded_audio_stream = audio_stream
	if audio_stream is AudioStreamWAV:
		if recording_data != null:
			recording_data.audio_stream = audio_stream as AudioStreamWAV
		else:
			push_warning("RecordingData was null when set_recording_audio_stream was called — creating fallback RecordingData.")
			recording_data = RecordingData.new(self, -1, audio_stream as AudioStreamWAV)
			recording_data.state = RecordingData.State.RECORDING_DONE
	else:
		recording_data = null

func has_recording() -> bool:
	return recording_data != null and recording_data.audio_stream != null
