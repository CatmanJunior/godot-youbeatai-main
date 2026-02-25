extends Node

var recorded_audio: AudioStream = null
var audio_effect_record: AudioEffectRecord

var result: AudioStreamWAV = null

var recording: bool = false
var silence_length: float = 0.0
var recording_length: float = 0.0
var has_detected_sound: bool = false
var actual_sound_length: float = 0.0

var recording_volume: float
var current_recording_ring: int = 0

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

	result = AudioStreamWAV.new()
	result.data = trimmed_data

	return result

func _set_volume(value: float) -> void:
	var db: float = linear_to_db(value)
	for player in %AudioPlayerManager.audio_players:
		player.volume_db = db
		
func start_recording(ring: int) -> void:
	_set_volume(0.0)
	current_recording_ring = ring

	audio_effect_record.set_recording_active(true)
	recording = true

func stop_recording() -> void:
	_set_volume(1.0)

	audio_effect_record.set_recording_active(false)
	recorded_audio = audio_effect_record.get_recording()

	recording = false
	recorded_audio = _trim_audio_stream(recorded_audio, silence_length)
	has_detected_sound = false
	silence_length = 0.0
	recording_length = 0.0
	actual_sound_length = 0.0
	
	var player = %AudioPlayerManager.audio_players_rec[current_recording_ring]
	player.stop()
	player.stream = recorded_audio
		

func get_recording_volume() -> float:
	return %MicrophoneCapture.volume

func _ready():
	var bus_index: int = AudioServer.get_bus_index("Microphone")
	audio_effect_record = AudioServer.get_bus_effect(bus_index, 1) as AudioEffectRecord
	if audio_effect_record == null:
		print("no record effect found")

func _process(delta: float):
	if recording:
		recording_length += delta
		if get_recording_volume() > %UiManager.volume_threshold.value:
			has_detected_sound = true
		if not has_detected_sound:
			silence_length += delta

		if has_detected_sound:
			actual_sound_length += delta

			var base_time_per_beat: float = %BpmManager.base_time_per_beat
			if base_time_per_beat == 0.0:
				base_time_per_beat = 0.2

			var percentage: float = actual_sound_length / (base_time_per_beat * 2.0)
			# var fill: TextureProgressBar = get_child(0) as TextureProgressBar

			if percentage > 1.0:
				#TODO reset the recording button
				stop_recording()
			else:
				# fill.value = 1.0 - percentage
				pass
