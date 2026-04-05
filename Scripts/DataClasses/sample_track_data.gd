class_name SampleTrackData
extends TrackData

## Data class for a sample-based track within a section.
## Holds beat pattern state in addition to the base track properties.

## Beat activation pattern — one bool per beat
var beats: Array[bool] = []

var main_audio_stream: AudioStream = null
var alt_audio_stream: AudioStream = null

func _init(track_index: int, knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(track_index, knob_pos, TrackType.SAMPLE)
	var beats_amount = GameState.total_beats
	for i in range(beats_amount):
		beats.append(false)


func has_active_beats() -> bool:
	for active in beats:
		if active:
			return true
	return false

func get_beat_active(beat: int) -> bool:
	if beat < beats.size():
		return beats[beat]
	return false


func clear_beats() -> void:
	for i in range(beats.size()):
		beats[i] = false


func duplicate_track() -> TrackData:
	var copy: SampleTrackData = SampleTrackData.new(index, knob_position)
	for i in range(beats.size()):
		copy.beats[i] = beats[i]
	copy.master_volume = master_volume
	copy.weights = weights
	copy.main_audio_stream = main_audio_stream
	copy.alt_audio_stream = alt_audio_stream
	copy.recorded_audio_stream = recorded_audio_stream
	copy.recording_data = recording_data
	return copy
