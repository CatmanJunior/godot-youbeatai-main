class_name SampleTrackData
extends TrackData

## Data class for a sample-based track within a section.
## Holds beat pattern state in addition to the base track properties.

## Beat activation pattern — one bool per beat.
@export var beats: Array[bool] = []

## The main and alt audio streams loaded from the soundbank.
## These are Resources — saved automatically when the section is saved.
@export var main_audio_stream: AudioStream = null
@export var alt_audio_stream: AudioStream = null

func _init(track_index: int = -1, p_section_index: int = -1, knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(track_index, p_section_index, knob_pos, TrackType.SAMPLE)
	if beats.is_empty():
		var beats_amount = SongState.total_beats
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
	var copy: SampleTrackData = SampleTrackData.new(index, section_index, knob_position)
	for i in range(beats.size()):
		copy.beats[i] = beats[i]
	copy.master_volume = master_volume
	copy.weights = weights
	copy.main_audio_stream = main_audio_stream
	copy.alt_audio_stream = alt_audio_stream
	if recorded_audio_stream != null:
		copy.recorded_audio_stream = recorded_audio_stream
	if recording_data != null:
		copy.recording_data = recording_data.duplicate()
	return copy
