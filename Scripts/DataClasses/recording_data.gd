class_name RecordingData
extends Resource

## Data class encapsulating a recorded audio stream and the TrackData it belongs to.
## Tracks recording state and section context.

enum State { NOT_STARTED, RECORDING, PROCESSING, RECORDING_DONE }

@export var state: State = State.NOT_STARTED
@export var has_detected_sound: bool = false
@export var section_index: int = -1
## Back-reference to the owning TrackData. Not exported to avoid circular refs.
## Re-linked by TrackData after load via its recording_data setter.
var track_data: TrackData
@export var max_recording_length: float = 0.0
@export var actual_recording_length: float = 0.0
@export var length_since_detected_sound: float = 0.0
@export var audio_stream: AudioStreamWAV

var track_type: TrackData.TrackType:
	get():
		return track_data.track_type


func _init(p_track_data: TrackData = null, p_audio_stream: AudioStreamWAV = null) -> void:
	track_data = p_track_data
	if p_track_data != null:
		section_index = p_track_data.section_index
	if p_audio_stream:
		audio_stream = p_audio_stream


func get_duration() -> float:
	if audio_stream == null:
		return 0.0
	return audio_stream.get_length()

func get_recording_progress() -> float:
	return actual_recording_length / max_recording_length if max_recording_length > 0 else 0.0
	


# =========================================================
# Duplication
# =========================================================

## Returns a new RecordingData with the same state, section context, and a
## deep-copied AudioStreamWAV so the clone is fully independent.
## The caller is responsible for assigning the correct TrackData reference if
## it differs from the original (e.g. when attaching to a different track).
func duplicate_data(p_track_data: TrackData = null) -> RecordingData:
	var target_track: TrackData = p_track_data if p_track_data != null else track_data
	var copy := RecordingData.new(target_track)
	copy.state = state
	copy.has_detected_sound = has_detected_sound
	copy.section_index = section_index
	copy.max_recording_length = max_recording_length
	copy.actual_recording_length = actual_recording_length
	copy.length_since_detected_sound = length_since_detected_sound
	if audio_stream != null:
		var wav := AudioStreamWAV.new()
		wav.data = audio_stream.data.duplicate()
		wav.format = audio_stream.format
		wav.loop_mode = audio_stream.loop_mode
		wav.loop_begin = audio_stream.loop_begin
		wav.loop_end = audio_stream.loop_end
		wav.mix_rate = audio_stream.mix_rate
		wav.stereo = audio_stream.stereo
		copy.audio_stream = wav
	return copy
