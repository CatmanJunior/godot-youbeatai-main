extends Node

var recording: bool:
	get: return GameState.is_recording


var current_recording_data: RecordingData = null


@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

func _ready():
	EventBus.record_button_toggled.connect(_on_recording_sample_button_toggled)
	EventBus.recording_stopped.connect(_on_recording_stopped)

func _process(delta: float):
	if recording and current_recording_data:
		_handle_recording(delta)

func _handle_recording(delta: float) -> void:
	if get_recording_volume() > GameState.recording_volume_threshold:
		current_recording_data.has_detected_sound = true
	if not current_recording_data.has_detected_sound:
		return
	

	current_recording_data.actual_recording_length += delta
	

	var max_length := current_recording_data.max_recording_length

	var percentage: float = current_recording_data.actual_recording_length / max_length

	recording_sample_button.update_button(percentage)
	
	# Update progress bar (only for SYNTH tracks)
	if current_recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress_bar(current_recording_data, percentage)

	if percentage >= 1.0:
		_stop_recording()

func _start_recording() -> void:

	# Step 1: TrackData creates the RecordingData (no state change yet)
	current_recording_data = SongState.current_track.create_recording_data()
	current_recording_data.max_recording_length = _calculate_max_recording_length(current_recording_data.track_type)

	# Step 2: Mute all tracks
	EventBus.mute_all_requested.emit(true)

	# Step 3: If SYNTH → show countdown first, then start mic
	if current_recording_data.track_type == TrackData.TrackType.SYNTH:
		EventBus.countdown_show_requested.emit()
		#Wait for 4 seconds (countdown duration) before starting recording
		await get_tree().create_timer(4.0).timeout
		EventBus.countdown_close_requested.emit()
		

	# Step 4: Announce to the world that recording has started
	current_recording_data.state = RecordingData.State.RECORDING
	EventBus.recording_started.emit(current_recording_data)

func _stop_recording() -> void:
	EventBus.mute_all_requested.emit(false)
	EventBus.stop_recording_requested.emit(current_recording_data)


func _calculate_max_recording_length(track_type: TrackData.TrackType) -> float:
	match track_type:
		TrackData.TrackType.SAMPLE:
			return GameState.beat_duration * 1.2 # allow some extra time beyond 1 beat for user to finish playing
		TrackData.TrackType.SYNTH:
			return GameState.beat_duration * SongState.total_beats 
		TrackData.TrackType.SONG:
			return GameState.beat_duration * SongState.total_beats * SongState.section_count() 
	return GameState.beat_duration * 2.0 # default max length



#------------------Event Handlers----------------------
func _on_recording_sample_button_toggled(toggled: bool) -> void:
	if toggled and not recording:
		_start_recording()
	elif recording:
		_stop_recording()
	elif not toggled:
		# If button is toggled off but we're not recording, ensure everything is reset
		EventBus.mute_all_requested.emit(false)


func _on_recording_stopped(recording_data: RecordingData) -> void:
	if not recording_data:
		printerr("No current recording data on recording stopped!")
		return
	
	if not recording_data.has_detected_sound:
		recording_data.state = RecordingData.State.NOT_STARTED
		printerr("Recording stopped without detecting sound, marking as NOT_STARTED.")
		return

	recording_data.state = RecordingData.State.PROCESSING

	var audio: AudioStream = recording_data.audio_stream

	if recording_data.track_type == TrackData.TrackType.SAMPLE:
		audio = AudioHelpers.trim_audio_stream(recording_data.audio_stream, GameState.recording_volume_threshold)
		# Also cap to 1 beat duration so trailing audio is removed
		audio = AudioHelpers.cap_audio_duration(audio, GameState.beat_duration)

	# Update waveform visualization using RecordingData (only for SYNTH tracks)
	if recording_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_waveform(recording_data)
		waveform_visualizer.reset_progress_bar(recording_data)

	recording_data.audio_stream = audio
	recording_data.state = RecordingData.State.RECORDING_DONE
	EventBus.set_recorded_stream_requested.emit(recording_data)

func get_recording_volume() -> float:
	return GameState.microphone_volume
