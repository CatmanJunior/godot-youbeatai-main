extends Node

var recording: bool:
	get: return GameState.is_recording

var has_detected_sound: bool = false
var actual_sound_length: float = 0.0

var current_recording_track: TrackData = null

var track_type: TrackData.TrackType

@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

func _ready():
	EventBus.recording_sample_button_toggled.connect(_on_recording_sample_button_toggled)
	EventBus.recording_stopped.connect(_on_recording_stopped)

func _process(delta: float):
	if recording:
		_handle_recording(delta)

func _handle_recording(delta: float) -> void:
	if get_recording_volume() > GameState.recording_volume_threshold:
		has_detected_sound = true
	if not has_detected_sound:
		return
	
	actual_sound_length += delta

	var beats_to_record: int
	match track_type:
		TrackData.TrackType.SAMPLE:
			beats_to_record = 1
		TrackData.TrackType.SYNTH:
			beats_to_record = SongState.total_beats
		TrackData.TrackType.SONG:
			beats_to_record = SongState.total_beats * SongState.section_count()


	var percentage: float = actual_sound_length / (GameState.beat_duration * beats_to_record)

	recording_sample_button.update_button(percentage)
	
	# Update progress bar (only for SYNTH tracks)
	if track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress(SongState.selected_track_index, percentage)

	if percentage >= 1.0:
		_stop_recording()


func _start_recording() -> void:
	var cur_track_index = SongState.selected_track_index
	current_recording_track = SongState.current_section.tracks[cur_track_index]
	track_type = current_recording_track.track_type

	#Reset recording state
	has_detected_sound = false
	actual_sound_length = 0.0

	# Create RecordingData early so it tracks the full lifecycle
	current_recording_track.start_recording(SongState.current_section_index)

	#TODO maybe handle the muting in the audio manager instead of here based on starting/stopping recording
	EventBus.mute_all_requested.emit(true)
	EventBus.start_recording_requested.emit()

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
	if not has_detected_sound:
		if current_recording_track and current_recording_track.recording_data:
			current_recording_track.recording_data.state = RecordingData.State.NOT_STARTED
		return

	#TODO handle this in the trackdata or trackPlayer, or recording data??
	# Trim silence for sample tracks, keep full recording for loop tracks
	if track_type == TrackData.TrackType.SAMPLE:
		audio = AudioHelpers.trim_audio_stream(audio, GameState.recording_volume_threshold)
		# Also cap to 1 beat duration so trailing audio is removed
		audio = AudioHelpers.cap_audio_duration(audio, GameState.beat_duration)

	# Synth tracks enter PROCESSING for voice analysis; sample tracks finish immediately
	if track_type == TrackData.TrackType.SYNTH and current_recording_track.recording_data:
		current_recording_track.recording_data.state = RecordingData.State.PROCESSING

	# Store audio on the track (sets state to RECORDING_DONE for sample tracks)
	current_recording_track.set_recording_audio_stream(audio)

	# Update waveform visualization using RecordingData (only for SYNTH tracks)
	if track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_waveform(current_recording_track.index, current_recording_track.recording_data)
		waveform_visualizer.reset_progress(current_recording_track.index)

	EventBus.set_recorded_stream_requested.emit(current_recording_track.index, audio)

func get_recording_volume() -> float:
	return GameState.microphone_volume
