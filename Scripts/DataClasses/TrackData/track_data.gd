## Base data class for a single track within a section.
## Contains chaos pad knob position, mixing state, and audio player references.
## Extends Resource so the full track state (including recordings) can be saved/loaded.
class_name TrackData
extends Resource

enum TrackType { SAMPLE, SYNTH, SONG, EXPORT }

@export var track_type: TrackType = TrackType.SAMPLE

@export var index: int = -1

@export var section_index: int = -1

## Recorded audio from the microphone (AudioStreamWAV is a Resource — saved automatically).
@export var recorded_audio_stream: AudioStream = null

## Chaos pad knob position for mixing on this track.
@export var knob_position: Vector2 = Vector2(150,150)

## Current mixing state for this track.
@export var master_volume: float = 0.0
@export var weights: Vector3 = Vector3(0.3, 0.3, 0.4)

var recording_data: RecordingData = null

func _init(track_index:int, p_section_index: int, knob_pos: Vector2 = Vector2(150,150), type: TrackType = TrackType.SAMPLE) -> void:
	knob_position = knob_pos	
	
	self.track_type = type
	self.index = track_index
	self.section_index = p_section_index

func duplicate_track() -> TrackData:
	var copy : TrackData = TrackData.new(index, section_index, knob_position, track_type)
	copy.master_volume = master_volume
	copy.weights = weights
	if recorded_audio_stream:
		copy.recorded_audio_stream = recorded_audio_stream
	if recording_data:
		copy.recording_data = recording_data.duplicate()
	return copy

func create_recording_data() -> RecordingData:
	recording_data = RecordingData.new(self)
	return recording_data

func set_recording_audio_stream(p_recording_data: RecordingData) -> void:
	if p_recording_data.audio_stream == null:
		printerr("Attempted to set recording audio stream with null audio on track ", index)
		return
	
	recorded_audio_stream = p_recording_data.audio_stream

			
func has_recording() -> bool:
	return recording_data != null and recording_data.audio_stream != null
