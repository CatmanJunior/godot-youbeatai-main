extends Node

const NOTES: Notes = preload("res://Experimental/VoiceToSynth/notes.tres")

var recording: bool:
	get: return GameState.is_recording

var current_recording_data: RecordingData = null
var _thread: Thread = null

@export var song_recording_progress_bar: ProgressBar
@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

func _ready():
	EventBus.record_button_toggled.connect(_on_recording_button_toggled)
	EventBus.recording_stopped.connect(_on_recording_stopped)

func _process(delta: float):
	if recording and current_recording_data:
		_handle_recording(delta)

func _handle_recording(delta: float) -> void:
	if current_recording_data.track_type == TrackData.TrackType.SAMPLE:
		if get_recording_volume() > GameState.recording_volume_threshold:
			current_recording_data.has_detected_sound = true
		if not current_recording_data.has_detected_sound:
			return
	
	current_recording_data.actual_recording_length += delta
	
	recording_sample_button.update_button(current_recording_data.get_recording_progress())
	
	# Update progress bar (only for SYNTH tracks)
	if current_recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress_bar(current_recording_data, current_recording_data.get_recording_progress())

	if current_recording_data.track_data.track_type == TrackData.TrackType.SONG:
		song_recording_progress_bar.value = current_recording_data.get_recording_progress()

	if current_recording_data.get_recording_progress() >= 1.0:
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
		EventBus.playing_change_requested.emit(true)
		#Wait for 4 seconds (countdown duration) before starting recording
		var amount_to_wait = BeatManager.calculate_time_until_top() + 0.1
		await get_tree().create_timer(amount_to_wait).timeout
		EventBus.countdown_close_requested.emit()
		print("Starting recording after countdown, waited for: " + str(amount_to_wait) + " seconds")

	if current_recording_data.track_type == TrackData.TrackType.SONG:
		EventBus.section_switch_requested.emit(0) # switch to first section to ensure recording starts from the beginning
		

	# Step 4: Announce to the world that recording has started
	current_recording_data.state = RecordingData.State.RECORDING
	EventBus.recording_started.emit(current_recording_data)

func _stop_recording() -> void:
	EventBus.mute_all_requested.emit(false)
	EventBus.stop_recording_requested.emit(current_recording_data)
	current_recording_data = null


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
func _on_recording_button_toggled(toggled: bool) -> void:
	if toggled and current_recording_data == null:
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

	if not recording_data.has_detected_sound and recording_data.track_type == TrackData.TrackType.SAMPLE:
		recording_data.state = RecordingData.State.NOT_STARTED
		printerr("Recording stopped without detecting sound, marking as NOT_STARTED.")
		return

	recording_data.state = RecordingData.State.PROCESSING

	match recording_data.track_type:
		TrackData.TrackType.SAMPLE: _post_process_sample(recording_data)
		TrackData.TrackType.SYNTH:  _post_process_synth(recording_data)
		TrackData.TrackType.SONG:   _post_process_song(recording_data)

	EventBus.set_recorded_stream_requested.emit(recording_data)

func _post_process_sample(recording_data: RecordingData) -> void:
	var audio: AudioStream = recording_data.audio_stream
	# Use the timestamp to skip the bulk of the silence, then do an amplitude
	# scan on a small window around that point to find the precise attack onset.
	var silent_lead_time: float = audio.get_length() - recording_data.actual_recording_length
	audio = AudioHelpers.trim_sample_smart(audio, silent_lead_time)
	audio = AudioHelpers.cap_audio_duration(audio, GameState.beat_duration)
	recording_data.audio_stream = audio
	recording_data.state = RecordingData.State.RECORDING_DONE

func _post_process_synth(recording_data: RecordingData) -> void:
	waveform_visualizer.update_waveform(recording_data)
	waveform_visualizer.reset_progress_bar(recording_data)
	# State remains PROCESSING — thread sets RECORDING_DONE after voice analysis
	_thread = Thread.new()
	_thread.start(_run_voice_processing.bind(recording_data))

func _run_voice_processing(recording_data: RecordingData) -> void:
	var sequence: Sequence = VoiceProcessor.process_audio(recording_data.audio_stream, NOTES)
	call_deferred("_on_voice_processed", sequence, recording_data)

func _on_voice_processed(sequence: Sequence, recording_data: RecordingData) -> void:
	_thread.wait_to_finish()
	_thread = null
	EventBus.sequence_ready.emit(sequence, recording_data.track_data)

func _post_process_song(recording_data: RecordingData) -> void:
	recording_data.state = RecordingData.State.RECORDING_DONE

func get_recording_volume() -> float:
	return GameState.microphone_volume
