extends Node

var recording: bool:
	get: return GameState.is_recording

var has_detected_sound: bool = false
var actual_sound_length: float = 0.0

var current_recording_track: TrackData = null

var track_type: TrackData.TrackType

@export var recording_sample_button: Button
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

	var beats_to_record = 1 if track_type == TrackData.TrackType.SAMPLE else GameState.total_beats
	var percentage: float = actual_sound_length / (GameState.time_per_beat * beats_to_record)

	recording_sample_button.update_button(percentage)
	
	# Update progress bar (only for SYNTH tracks)
	if track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress(GameState.selected_track_index, percentage)

	if percentage >= 1.0:
		_stop_recording()


func _start_recording() -> void:
	var cur_track_index = GameState.selected_track_index
	current_recording_track = GameState.current_section.tracks[cur_track_index]
	track_type = current_recording_track.track_type

	#Reset recording state
	has_detected_sound = false
	actual_sound_length = 0.0

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
		return

	# Trim silence for sample tracks, keep full recording for loop tracks
	if track_type == TrackData.TrackType.SAMPLE:
		audio = AudioHelpers.trim_audio_stream(audio, GameState.recording_volume_threshold)

	# Update waveform visualization with the final recorded audio (only for SYNTH tracks)
	if track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_waveform(current_recording_track.index, audio)
		waveform_visualizer.reset_progress(current_recording_track.index)

	EventBus.set_recorded_stream_requested.emit(current_recording_track.index, audio)


func get_recording_volume() -> float:
	return GameState.microphone_volume
