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
		_set_recorded_stream(rec)

func _ready() -> void:
	super._ready()
	EventBus.play_track_requested.connect(_on_play_track_requested)

func _process(delta: float) -> void:
	if not _is_recording:
		return
	# Wait for sound detection before counting recording time
	if not _has_detected_sound:
		if _get_recording_volume() > GameState.recording_volume_threshold:
			_has_detected_sound = true
		return
	_recording_time += delta
	var percentage: float = _recording_time / GameState.beat_duration
	EventBus.recording_progress_updated.emit(track_index, percentage)
	if percentage >= 1.0:
		_end_recording()

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

func _on_section_switched(_new) -> void:
	
	if _new.tracks[track_index].recorded_audio_stream != null:
		_set_recorded_stream(_new.tracks[track_index].recorded_audio_stream)
	else:
		# Clear recording stream and flag if new section doesn't have a recording for this track
		players[2].stream = null
		_has_recording = false
	set_weights(_new.tracks[track_index].weights) # apply new section's weights for this track
	set_volume_db(_new.tracks[track_index].master_volume) # apply new section's master volume for this track

func _on_beat_triggered(beat: int) -> void:
	if track_data.get_beat_active(beat):
		play()

func _set_recorded_stream(rec: AudioStream) -> void:
	players[2].stream = rec
	_has_recording = true
	if track_data:
		track_data.set_recording_audio_stream(rec)
	set_weights(_weights) # update volumes to include recording bus

# ── Recording ────────────────────────────────────────────────────────────────

func _begin_recording() -> void:
	_is_recording = true
	_has_detected_sound = false
	_recording_time = 0.0
	# Create recording data on the track
	track_data.create_recording_data(SongState.current_section_index)
	track_data.recording_data.state = RecordingData.State.RECORDING
	# Mute all tracks and start mic — recording clock starts when sound is detected
	EventBus.mute_all_requested.emit(true)
	EventBus.start_recording_requested.emit()

func _on_mic_recording_stopped(audio: AudioStream) -> void:
	if not _is_recording:
		return
	_is_recording = false
	_recording_time = 0.0

	if not _has_detected_sound or audio == null:
		# No sound detected or no audio — cancel recording
		if track_data and track_data.recording_data:
			track_data.recording_data.state = RecordingData.State.NOT_STARTED
		_has_detected_sound = false
		return
	_has_detected_sound = false

	# Trim leading silence and cap to 1 beat duration
	audio = AudioHelpers.trim_audio_stream(audio, GameState.recording_volume_threshold)
	audio = AudioHelpers.cap_audio_duration(audio, GameState.beat_duration)

	# Store audio on the track data and mark as done
	track_data.set_recording_audio_stream(audio)
	track_data.recording_data.state = RecordingData.State.RECORDING_DONE

	# Update the player's recording layer
	players[2].stream = audio
	_has_recording = true
	set_weights(_weights)

## Playback control (called by Section when starting/stopping playback)
## Offset: for starting in the middle of a track. Value is in seconds.
func play(offset: float = 0.0) -> void:
	players[0].play(offset)
	players[1].play(offset)
	if _has_recording:
		players[2].play(offset)
