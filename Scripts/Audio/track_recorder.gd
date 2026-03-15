extends Node

var mic: MicrophoneRecorder

var trimmed_audio_stream: AudioStream = null
var result: AudioStreamWAV = null

var recording: bool:
	get: return mic.recording if mic else false

var silence_length: float = 0.0
var recording_length: float = 0.0
var has_detected_sound: bool = false
var actual_sound_length: float = 0.0

var recording_volume: float
var current_selected_track: TrackData = null

@export var recording_sample_button: Button

func _ready():
	EventBus.recording_sample_button_toggled.connect(_on_recording_sample_button_toggled)
	EventBus.track_selected.connect(_on_track_selected)

	mic = %MicrophoneCapture

func _process(delta: float):
	if recording:
		_handle_recording(delta)

func _handle_recording(delta: float) -> void:
	recording_length += delta
	if get_recording_volume() > GameState.recording_volume_threshold:
		print("Detected sound with volume: %s" % get_recording_volume())
		has_detected_sound = true
	if not has_detected_sound:
		silence_length += delta
		return
	
	actual_sound_length += delta

	var beats_to_record = 1 if current_selected_track.track_type == TrackData.TrackType.SAMPLE else GameState.beats_amount

	var percentage: float = actual_sound_length / (GameState.base_time_per_beat * beats_to_record)
	
	if percentage > 1.0:
		recording_sample_button.button_pressed = false
		_stop_recording()
	else:
		recording_sample_button.set_fill(1-percentage)
		

#------------------Event Handlers----------------------
func _on_track_selected(track: int) -> void:
	current_selected_track = GameState.current_section.tracks[track]

func _on_recording_sample_button_toggled(toggled: bool) -> void:
	print("Recording sample button toggled: %s" % toggled)
	if toggled and not recording:
		_start_recording()
	elif recording:
		_stop_recording()

func _trim_audio_stream(original: AudioStream, seconds_to_trim: float) -> AudioStream:
	var original_data: PackedByteArray = original.data
	var audio_length: float = original.get_length()

	if audio_length <= 0.0:
		print("Invalid audio length.")
		return original

	var bytes_per_second: float = float(original_data.size()) / audio_length
	var frame_size: int = (2 if original.get("stereo") else 1) * \
		(2 if original.get("format") == 1 else 1)
	var raw_trim_bytes: int = int(seconds_to_trim * bytes_per_second)
	@warning_ignore("integer_division")
	var aligned_trim_bytes: int = (raw_trim_bytes / frame_size) * frame_size

	print("Trim %s seconds → %s bytes" % [seconds_to_trim, aligned_trim_bytes])

	if aligned_trim_bytes >= original_data.size():
		print("Trim amount exceeds or matches original audio length.")
		return original

	var trimmed_data: PackedByteArray = original_data.slice(aligned_trim_bytes)

	var trimmed: AudioStreamWAV = AudioStreamWAV.new()
	trimmed.data = trimmed_data
	trimmed.mix_rate = original.mix_rate
	trimmed.stereo = original.stereo
	trimmed.format = original.format

	return trimmed

func _start_recording() -> void:
	EventBus.request_mute_all.emit(true)
	EventBus.request_start_recording.emit()

func _stop_recording() -> void:
	EventBus.request_mute_all.emit(false)
	EventBus.request_stop_recording.emit()

func _on_recording_stopped(audio: AudioStream) -> void:
	trimmed_audio_stream = _trim_audio_stream(audio, silence_length)
	has_detected_sound = false
	silence_length = 0.0
	recording_length = 0.0
	actual_sound_length = 0.0
	EventBus.request_set_stream.emit(GameState.selected_track_index, 2, trimmed_audio_stream) 

func get_recording_volume() -> float:
	return GameState.microphone_volume
