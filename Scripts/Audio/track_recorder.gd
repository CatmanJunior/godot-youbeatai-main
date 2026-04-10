extends Node

var recording: bool:
	get: return GameState.is_recording

var actual_sound_length: float = 0.0

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
	
	actual_sound_length += delta

	var max_length := current_recording_data.max_recording_length


	var percentage: float = actual_sound_length / max_length

	recording_sample_button.update_button(percentage)
	
	# Update progress bar (only for SYNTH tracks)
	if current_recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress_bar(current_recording_data, percentage)

	if percentage >= 1.0:
		_stop_recording()


func _start_recording() -> void:
	actual_sound_length = 0.0

	# Create RecordingData early so it tracks the full lifecycle
	current_recording_data = SongState.current_track.start_recording(SongState.current_section_index)
	
	var max_recording_length: float = _calculate_max_recording_length(current_recording_data.track_data.track_type)
	current_recording_data.max_recording_length = max_recording_length

	EventBus.mute_all_requested.emit(true)
	EventBus.start_recording_requested.emit(current_recording_data)


func _calculate_max_recording_length(track_type: TrackData.TrackType) -> float:
	match track_type:
		TrackData.TrackType.SAMPLE:
			return GameState.beat_duration * 1.2 # allow some extra time beyond 1 beat for user to finish playing
		TrackData.TrackType.SYNTH:
			return GameState.beat_duration * SongState.total_beats 
		TrackData.TrackType.SONG:
			return GameState.beat_duration * SongState.total_beats * SongState.section_count() 
	return GameState.beat_duration * 2.0 # default max length


func _stop_recording() -> void:
	EventBus.mute_all_requested.emit(false)
	EventBus.stop_recording_requested.emit()

#------------------Event Handlers----------------------
func _on_recording_sample_button_toggled(toggled: bool) -> void:
	if toggled and not recording:
		_start_recording()
	elif recording:
		_stop_recording()
	elif not toggled:
		# If button is toggled off but we're not recording, ensure everything is reset
		EventBus.mute_all_requested.emit(false)


func _on_recording_stopped(audio: AudioStream) -> void:
	if not current_recording_data:
		printerr("No current recording data on recording stopped!")
		return
	
	if not current_recording_data.has_detected_sound:
		current_recording_data.state = RecordingData.State.NOT_STARTED
		return

	current_recording_data.state = RecordingData.State.PROCESSING

	#TODO handle this in the trackdata or trackPlayer, or recording data??
	# Trim silence for sample tracks, keep full recording for loop tracks
	if current_recording_data.track_data.track_type == TrackData.TrackType.SAMPLE:
		audio = AudioHelpers.trim_audio_stream(audio, GameState.recording_volume_threshold)
		# Also cap to 1 beat duration so trailing audio is removed
		audio = AudioHelpers.cap_audio_duration(audio, GameState.beat_duration)

	#TODO: wait isnt this also set somewhere else?? maybe handle all of this in the track player or track data instead of here??
	# Store audio on the track (sets state to RECORDING_DONE for sample tracks)
	current_recording_data.track_data.set_recording_audio_stream(audio)

	# Update waveform visualization using RecordingData (only for SYNTH tracks)
	if current_recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_waveform(current_recording_data)
		waveform_visualizer.reset_progress_bar(current_recording_data)

	EventBus.set_recorded_stream_requested.emit(current_recording_data.track_data.index, audio)

func get_recording_volume() -> float:
	return GameState.microphone_volume
