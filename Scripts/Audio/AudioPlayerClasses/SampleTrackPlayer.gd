class_name SampleTrackPlayer
extends TrackPlayerBase

var BUS_SUFFIXES : Array[String] = ["Main", "Alt", "Rec"]

var BUS_PREFIX : String = "Sample"

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

# --- Public API ---

func set_streams(a: AudioStream, b: AudioStream, rec: AudioStream=null) -> void:
	players[0].stream = a
	players[1].stream = b
	if track_data:
		track_data.main_audio_stream = a
		track_data.alt_audio_stream = b
	if rec != null:
		var rec_data = track_data.create_recording_data()
		rec_data.audio_stream = rec
		rec_data.state = RecordingData.State.RECORDING_DONE
		_set_recorded_stream(rec_data)

func _ready() -> void:
	super._ready()
	EventBus.play_track_requested.connect(_on_play_track_requested)

func _on_audio_bank_loaded(bank: AudioBank) -> void:
	match track_index:
		0:
			set_streams(bank.kick, bank.kick_alt)
		1:
			set_streams(bank.clap, bank.clap_alt)
		2:
			set_streams(bank.snare, bank.snare_alt)
		3:
			set_streams(bank.closed, bank.closed_alt)
	
func _on_play_track_requested(trackIndex: int) -> void:
	if trackIndex == track_index:
		play()

func _on_section_switched(_new : SectionData) -> void:
	
	if _new.tracks[track_index].recording_data and _new.tracks[track_index].recording_data.audio_stream:
		_set_recorded_stream(_new.tracks[track_index].recording_data)
	else:
		# Clear recording stream and flag if new section doesn't have a recording for this track
		players[2].stream = null
		_has_recording = false
	set_weights(_new.tracks[track_index].weights) # apply new section's weights for this track
	set_volume_db(_new.tracks[track_index].master_volume) # apply new section's master volume for this track

func _on_beat_triggered(beat: int) -> void:
	if track_data.get_beat_active(beat):
		play()

func _set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data.track_data.index != track_index:
		return
	if recording_data.section_index != track_data.section_index:
		return
	players[2].stream = recording_data.stream
	_has_recording = true
	if track_data:
		track_data.set_recording_audio_stream(recording_data)
	set_weights(_weights) # update volumes to include recording bus

## Playback control (called by Section when starting/stopping playback)
## Offset: for starting in the middle of a track. Value is in seconds.
func play(offset: float = 0.0) -> void:
	players[0].play(offset)
	players[1].play(offset)
	if _has_recording:
		players[2].play(offset)
