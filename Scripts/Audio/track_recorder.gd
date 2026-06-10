extends Node

const NOTES: Notes = preload("res://Experimental/VoiceToSynth/notes.tres")
const RECORDING_GRACE_FACTOR: float = 1.2
const RECORDING_FALLBACK_BEATS: float = 2.0

var recording: bool:
	get: return GameState.is_recording

var current_recording_data: RecordingData = null
var pre_recording_volume: float = 0

@export var song_recording_progress_bar: ProgressBar
@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

var timer: SceneTreeTimer 
var timer_wait_time: float = 1.5

func _ready():
	EventBus.record_button_toggled.connect(_on_recording_button_toggled)
	EventBus.recording_stopped.connect(_on_recording_stopped)

func _process(delta: float):
	if recording and current_recording_data:
		_handle_recording(delta)

	if timer and timer.time_left > 0:
		recording_sample_button.update_button(1 - (timer.time_left / timer_wait_time), Color.CORNSILK)

func _handle_recording(delta: float) -> void:
	if current_recording_data.state != RecordingData.State.RECORDING:
		return

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
		print("Max recording length reached, stopping recording.")
		_stop_recording()

func _start_recording() -> void:
	GameState.is_recording = true
	# Step 1: TrackData creates the RecordingData (no state change yet)
	current_recording_data = SongState.current_track.create_recording_data()
	current_recording_data.max_recording_length = _calculate_max_recording_length(current_recording_data.track_type)

	# Step 2: Mute all tracks
	# EventBus.mute_all_requested.emit(true)
	pre_recording_volume = AudioServer.get_bus_volume_db(0)
	

	# Step 3: If SYNTH → show countdown first, then start mic
	if current_recording_data.track_type == TrackData.TrackType.SYNTH:
		EventBus.countdown_show_requested.emit()
		EventBus.playing_change_requested.emit(true)
		GameState.metronome_enabled = true
		#Wait for 4 seconds (countdown duration) before starting recording
		var amount_to_wait = BeatManager.calculate_time_until_top()
		await get_tree().create_timer(amount_to_wait).timeout
		
		GameState.metronome_enabled = false
		EventBus.countdown_close_requested.emit()
		print("Starting recording after countdown, waited for: " + str(amount_to_wait) + " seconds")

	elif current_recording_data.track_type == TrackData.TrackType.SONG:
		GameState.song_mode_active = false
		GameState.metronome_enabled = true
		EventBus.countdown_show_requested.emit()
		EventBus.playing_change_requested.emit(true) # start playing
		
		var amount_to_wait = BeatManager.calculate_time_until_top()
		await get_tree().create_timer(amount_to_wait).timeout
		GameState.song_mode_active = true
		GameState.metronome_enabled = false
		EventBus.section_switch_requested.emit(0) # switch to first section to ensure recording starts from the beginning
		EventBus.countdown_close_requested.emit()

	elif current_recording_data.track_type == TrackData.TrackType.SAMPLE:
		timer = get_tree().create_timer(timer_wait_time)
		await timer.timeout
		
	EventBus.set_master_volume_db.emit(-20)
	# delay the actual recording a bit to clean the buffer of audio that is now processing
	timer = get_tree().create_timer(GameState.recording_delay_seconds)
	await timer.timeout

	# Step 4: Announce to the world that recording has started
	current_recording_data.state = RecordingData.State.RECORDING
	EventBus.recording_started.emit(current_recording_data)

func _stop_recording() -> void:
	GameState.is_recording = false
	EventBus.mute_all_requested.emit(false)
	EventBus.set_master_volume_db.emit(pre_recording_volume)
	EventBus.stop_recording_requested.emit(current_recording_data)	
	current_recording_data = null


func _calculate_max_recording_length(track_type: TrackData.TrackType) -> float:
	match track_type:
		TrackData.TrackType.SAMPLE:
			return SongState.beat_duration * 2.1 # allow some extra time beyond 1 beat for user to finish playing
		TrackData.TrackType.SYNTH:
			return SongState.beat_duration * SongState.beats_per_section 
		TrackData.TrackType.SONG:
			return SongState.beat_duration * SongState.beats_per_section * SongState.section_count() 
	return SongState.beat_duration * RECORDING_FALLBACK_BEATS # default max length



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
	audio = AudioHelpers.cap_audio_duration(audio, _calculate_max_recording_length(current_recording_data.track_type) )
	recording_data.audio_stream = audio
	recording_data.state = RecordingData.State.RECORDING_DONE

func _post_process_synth(recording_data: RecordingData) -> void:
	waveform_visualizer.update_waveform(recording_data)
	waveform_visualizer.reset_progress_bar(recording_data)
	# Voice analysis is finalized by SynthVoiceRecorder via EventBus.recording_stopped

func _post_process_song(recording_data: RecordingData) -> void:
	recording_data.state = RecordingData.State.RECORDING_DONE

func get_recording_volume() -> float:
	return GameState.microphone_volume
