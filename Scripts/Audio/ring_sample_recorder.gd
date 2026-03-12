extends Node

## Ring sample recording: immediate start, auto-stops when the captured sound
## reaches 2× the current beat length, trims leading silence, then publishes
## the result via EventBus. Delegates mic capture to MicrophoneRecorder.

var mic: MicrophoneRecorder

var recorded_audio: AudioStream = null
var result: AudioStreamWAV = null

var recording: bool:
	get: return mic.recording if mic else false

var silence_length: float = 0.0
var recording_length: float = 0.0
var has_detected_sound: bool = false
var actual_sound_length: float = 0.0

var recording_volume: float
var current_recording_ring: int = 0

var recording_volume_threshold: float = 0.1
var base_time_per_beat: float

@export var recording_sample_button: Button

func _ready():
	EventBus.recording_volume_threshold_changed.connect(_on_recording_volume_threshold_changed)
	EventBus.recording_sample_button_toggled.connect(_on_recording_sample_button_toggled)
	EventBus.ring_selected.connect(_on_ring_selected)
	EventBus.bpm_changed.connect(_on_bpm_changed)

	mic = %MicrophoneCapture

func _process(delta: float):
	if recording:
		_handle_recording(delta)

func _handle_recording(delta: float) -> void:
	recording_length += delta
	if get_recording_volume() > recording_volume_threshold:
		print("Detected sound with volume: %s" % get_recording_volume())
		has_detected_sound = true
	if not has_detected_sound:
		silence_length += delta
		return
	
	actual_sound_length += delta
	print(base_time_per_beat)
	var percentage: float = actual_sound_length / (base_time_per_beat * 2.0)
	print("Recording... length: %s seconds, actual sound length: %s seconds, percentage: %s" %
		[recording_length, actual_sound_length, percentage])
	
	if percentage > 1.0:
		recording_sample_button.button_pressed = false
		_stop_recording()
	else:
		recording_sample_button.set_fill(1-percentage)
		

#------------------Event Handlers----------------------
func _on_bpm_changed(bpm: float) -> void:
	base_time_per_beat = 60.0 / bpm

func _on_ring_selected(ring: int) -> void:
	current_recording_ring = ring

func _on_recording_sample_button_toggled(toggled: bool) -> void:
	print("Recording sample button toggled: %s" % toggled)
	if toggled and not recording:
		_start_recording()
	elif recording:
		_stop_recording()

func _on_recording_volume_threshold_changed(threshold: float) -> void:
	print("Recording volume threshold changed to: %s" % threshold)
	recording_volume_threshold = threshold


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
	mic.start_recording()

func _stop_recording() -> void:
	EventBus.request_mute_all.emit(false)
	recorded_audio = mic.stop_recording()
	recorded_audio = _trim_audio_stream(recorded_audio, silence_length)
	has_detected_sound = false
	silence_length = 0.0
	recording_length = 0.0
	actual_sound_length = 0.0
	
	EventBus.request_set_stream.emit(current_recording_ring, 2, recorded_audio)

func get_recording_volume() -> float:
	return EventBus.microphone_volume
