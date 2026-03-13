class_name SampleTrackData
extends TrackData

## Data class for a sample-based track within a section.
## Holds beat pattern state in addition to the base track properties.

## Beat activation pattern — one bool per beat
var beats: Array[bool] = []

var main_audio_stream: AudioStream = null
var alt_audio_stream: AudioStream = null

func _init(default_knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(default_knob_pos, TrackType.SAMPLE)
	beats = []
	var beats_amount = GameState.BEATS_AMOUNT_DEFAULT
	for i in range(beats_amount):
		beats.append(false)


func has_active_beats() -> bool:
	for active in beats:
		if active:
			return true
	return false


func clear_beats() -> void:
	for i in range(beats.size()):
		beats[i] = false


func duplicate_track() -> TrackData:
	var copy: SampleTrackData = SampleTrackData.new(knob_position)
	for i in range(beats.size()):
		copy.beats[i] = beats[i]
	copy.master_volume = master_volume
	copy.weights = weights
	copy.main_audio_stream = main_audio_stream
	copy.alt_audio_stream = alt_audio_stream
	copy.recorded_audio_stream = recorded_audio_stream
	return copy
