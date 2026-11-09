extends Node

const NOTES: Notes = preload("res://Experimental/VoiceToSynth/notes.tres")
const RECORDING_GRACE_FACTOR: float = 1.2
const RECORDING_FALLBACK_BEATS: float = 2.0
## Minimum extra beats captured beyond the section length for SYNTH recordings.
const SYNTH_RECORDING_EXTRA_BEATS: int = 2

var recording: bool:
	get: return GameState.is_recording

var current_recording_data: RecordingData = null
var pre_recording_volume: float = 0

@export var song_recording_progress_bar: ProgressBar
@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

var timer: SceneTreeTimer
var timer_wait_time: float = 1.5

## Number of beats elapsed since the SYNTH capture truly started. Used to stop
## the recording on the same beat clock the beat-ring pointer follows.
var _synth_beats_recorded: int = 0

func _ready():
	EventBus.record_button_toggled.connect(_on_recording_button_toggled)
	EventBus.recording_stopped.connect(_on_recording_stopped)
	EventBus.beat_triggered.connect(_on_beat_triggered_during_record)

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

	# Follow the pointer for one loop, then stay full during the extra capture.
	if current_recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		var progress: float = 1.0 if _synth_beats_recorded >= SongState.beats_per_section else GameState.bar_progress
		waveform_visualizer.update_progress_bar(current_recording_data, progress)

	if current_recording_data.track_data.track_type == TrackData.TrackType.SONG:
		song_recording_progress_bar.value = current_recording_data.get_recording_progress()

	if current_recording_data.track_type != TrackData.TrackType.SYNTH and current_recording_data.get_recording_progress() >= 1.0:
		print("Max recording length reached, stopping recording.")
		_stop_recording()

func _start_recording() -> void:
	if GameState.is_recording:
		printerr("Attempted to start recording while already recording!")
		return
	EventBus.beat_seek_requested.emit(0)
	GameState.is_recording = true
	# Step 1: TrackData creates the RecordingData (no state change yet)
	current_recording_data = SongState.current_track.create_recording_data()
	current_recording_data.max_recording_length = _calculate_max_recording_length(current_recording_data.track_type)

	# Step 2: Mute all tracks
	# EventBus.mute_all_requested.emit(true)
	pre_recording_volume = AudioServer.get_bus_volume_db(0)


	# Step 3: If SYNTH → show countdown first, then start mic
	if current_recording_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.set_waveform_visible(current_recording_data, false)
		EventBus.countdown_show_requested.emit()
		EventBus.playing_change_requested.emit(true)
		EventBus.metronome_do_amount.emit(3)
		# Start capture on the actual next loop boundary, not an estimated timer.
		while true:
			var beat: int = await EventBus.beat_triggered
			if beat == 0:
				break

		GameState.metronome_enabled = false
		EventBus.countdown_close_requested.emit()
		print("Starting recording at the loop boundary")

	elif current_recording_data.track_type == TrackData.TrackType.SONG:
		GameState.song_mode_active = false
		GameState.metronome_enabled = true
		EventBus.countdown_show_requested.emit()
		EventBus.playing_change_requested.emit(true) # start playing

		timer_wait_time = BeatManager.calculate_time_until_top()
		timer = get_tree().create_timer(timer_wait_time)
		await timer.timeout
		GameState.song_mode_active = true
		GameState.metronome_enabled = false
		EventBus.section_switch_requested.emit(0) # switch to first section to ensure recording starts from the beginning
		EventBus.countdown_close_requested.emit()

	elif current_recording_data.track_type == TrackData.TrackType.SAMPLE:
		timer = get_tree().create_timer(timer_wait_time)
		await timer.timeout

	#Set the master volume to -20 dB to avoid feedback during recording
	EventBus.set_master_volume_db.emit(-20)

	# Count beats after capture starts; the starting beat has already fired.
	_synth_beats_recorded = 0

	# Step 5: Announce to the world that recording has started
	current_recording_data.state = RecordingData.State.RECORDING
	EventBus.recording_started.emit(current_recording_data)

func _stop_recording() -> void:
	GameState.is_recording = false
	EventBus.mute_all_requested.emit(false)
	EventBus.set_master_volume_db.emit(pre_recording_volume)
	EventBus.stop_recording_requested.emit(current_recording_data)
	current_recording_data = null
	recording_sample_button.update_button(1.0)


func _calculate_max_recording_length(track_type: TrackData.TrackType) -> float:
	match track_type:
		TrackData.TrackType.SAMPLE:
			return SongState.beat_duration * 2.1 # allow some extra time beyond 1 beat for user to finish playing
		TrackData.TrackType.SYNTH:
			return SongState.beat_duration * (SongState.beats_per_section + _synth_extra_beats())
		TrackData.TrackType.SONG:
			return SongState.beat_duration * SongState.beats_per_section * SongState.section_count()
	return SongState.beat_duration * RECORDING_FALLBACK_BEATS # default max length

# Calculates extra beats needed for SYNTH recordings to account for recording delay.
func _synth_extra_beats() -> int:
	var shortest_beat: float = SongState.beat_duration * (1.0 - absf(SongState.swing))
	if shortest_beat <= 0.0:
		return SYNTH_RECORDING_EXTRA_BEATS
	return maxi(SYNTH_RECORDING_EXTRA_BEATS, int(ceil(GameState.recording_delay_seconds / shortest_beat)) + 1)


#------------------Event Handlers----------------------
func _on_beat_triggered_during_record(_beat: int) -> void:
	# Stop a SYNTH recording after exactly one full section, measured on the
	# beat clock so the captured length matches the visible loop.
	if not GameState.is_recording or current_recording_data == null:
		return
	if current_recording_data.state != RecordingData.State.RECORDING:
		return
	if current_recording_data.track_type != TrackData.TrackType.SYNTH:
		return
	_synth_beats_recorded += 1
	if _synth_beats_recorded >= SongState.beats_per_section + _synth_extra_beats():
		_stop_recording()

func _on_recording_button_toggled(toggled: bool) -> void:
	if GameState.is_recording:
		return
		# _stop_recording()
	if toggled and current_recording_data == null:
		_start_recording()
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
		TrackData.TrackType.SONG: _post_process_song(recording_data)

	# SYNTH recordings are finalized (trim/cap, waveform, recorded-stream emit)
	# by SynthVoiceRecorder, which runs after this handler.
	if recording_data.track_type != TrackData.TrackType.SYNTH:
		EventBus.set_recorded_stream_requested.emit(recording_data)

func _post_process_sample(recording_data: RecordingData) -> void:
	var audio: AudioStream = recording_data.audio_stream
	# Use the timestamp to skip the bulk of the silence, then do an amplitude
	# scan on a small window around that point to find the precise attack onset.
	var silent_lead_time: float = audio.get_length() - recording_data.actual_recording_length
	audio = AudioHelpers.trim_sample_smart(audio, silent_lead_time)
	audio = AudioHelpers.cap_audio_duration(audio, _calculate_max_recording_length(current_recording_data.track_type))
	recording_data.audio_stream = audio
	recording_data.state = RecordingData.State.RECORDING_DONE

func _post_process_song(recording_data: RecordingData) -> void:
	recording_data.state = RecordingData.State.RECORDING_DONE

func get_recording_volume() -> float:
	return GameState.microphone_volume
