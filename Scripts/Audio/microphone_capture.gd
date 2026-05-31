class_name MicrophoneRecorder
extends Node

## Manages the microphone: live spectrum analysis (clap/stamp detection,
## volume level) AND audio recording via AudioEffectRecord.

@export var bus_name: String = BusNames.MICROPHONE_BUS

static var analyzer: AudioEffectSpectrumAnalyzerInstance

var audio_stream_player: AudioStreamPlayer
var microphone: AudioStreamMicrophone

# Recording
var audio_effect_record: AudioEffectRecord

# Wall-clock start time of the current recording, in milliseconds.
# Used to recover the *actual* sample rate the browser delivered on web
# builds, where AudioServer.get_mix_rate() can disagree with the real
# rate of the AudioWorklet/microphone feed and produce chipmunk-pitched
# playback.
var _recording_start_msec: int = -1

# Sanity bounds for the measured sample rate. Outside this range we fall
# back to AudioServer.get_mix_rate() (e.g. for paused tabs or sub-second
# recordings where the measurement is too noisy to trust).
const _MIN_PLAUSIBLE_RATE: float = 8000.0
const _MAX_PLAUSIBLE_RATE: float = 96000.0

func _ready():
	EventBus.recording_started.connect(_start_recording)
	EventBus.stop_recording_requested.connect(_stop_recording)
	microphone = AudioStreamMicrophone.new()
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	audio_stream_player.stream = microphone
	audio_stream_player.bus = bus_name

	var bus_index: int = AudioServer.get_bus_index(bus_name)

	analyzer = AudioServer.get_bus_effect_instance(
		bus_index, AudioServer.get_bus_effect_count(bus_index) - 1
	) as AudioEffectSpectrumAnalyzerInstance

	assert(analyzer != null, "Could not find AudioEffectSpectrumAnalyzerInstance on bus: " + bus_name)

	# Recording effect (expected at effect index 1)
	if bus_index >= 0:
		audio_effect_record = AudioServer.get_bus_effect(bus_index, 1) as AudioEffectRecord
	if audio_effect_record == null:
		push_warning("MicrophoneRecorder: no AudioEffectRecord found on %s bus, effect 1" % bus_name)

	audio_stream_player.play()

func _process(_delta: float):
	GameState.microphone_volume = get_magnitude(0.0, 20000.0)

# -- Recording -----------------------------------------------------------------
func _start_recording(_recording_data: RecordingData) -> void:
	if audio_effect_record:
		_recording_start_msec = Time.get_ticks_msec()
		audio_effect_record.set_recording_active(true)
	else:
		push_error("Cannot start recording: no AudioEffectRecord found on bus '%s'." % bus_name)

func _stop_recording(recording_data: RecordingData) -> void:
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		var audio = audio_effect_record.get_recording()
		if audio != null:
			_correct_mix_rate(audio)
		if recording_data:
			recording_data.audio_stream = audio  # Put audio ON the RecordingData
	_recording_start_msec = -1
	EventBus.recording_stopped.emit(recording_data)

# On web, the AudioStreamWAV returned by AudioEffectRecord is stamped with
# AudioServer.get_mix_rate() (e.g. 48000), but the browser's microphone
# worklet often feeds samples at a different effective rate. The result is
# a recording that plays back too fast / pitched up. We re-derive the rate
# from the actual number of frames in the recording divided by wall-clock
# duration, and overwrite mix_rate with that.
func _correct_mix_rate(audio: AudioStreamWAV) -> void:
	if _recording_start_msec < 0:
		return
	var elapsed_msec: int = Time.get_ticks_msec() - _recording_start_msec
	if elapsed_msec <= 250:
		# Too short to measure reliably; trust AudioServer's reported rate.
		return
	var frame_count: int = _frame_count(audio)
	if frame_count <= 0:
		return
	var elapsed_s: float = float(elapsed_msec) / 1000.0
	var measured_rate: float = float(frame_count) / elapsed_s
	if measured_rate < _MIN_PLAUSIBLE_RATE or measured_rate > _MAX_PLAUSIBLE_RATE:
		return
	var corrected: int = int(round(measured_rate))
	if corrected != audio.mix_rate:
		print("MicrophoneRecorder: correcting WAV mix_rate from %d to %d (measured from %d frames over %.3fs)"
			% [audio.mix_rate, corrected, frame_count, elapsed_s])
		audio.mix_rate = corrected

# Number of audio frames (samples per channel) in the recorded WAV.
static func _frame_count(audio: AudioStreamWAV) -> int:
	var raw: PackedByteArray = audio.data
	var channels: int = 2 if audio.stereo else 1
	var bytes_per_sample: int = 2 if audio.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var frame_bytes: int = bytes_per_sample * channels
	if frame_bytes <= 0:
		return 0
	@warning_ignore("integer_division")
	return raw.size() / frame_bytes

# -- Helpers -------------------------------------------------------------------
static func get_magnitude(freq_min: float, freq_max: float, p_analyzer: AudioEffectSpectrumAnalyzerInstance = analyzer) -> float:
	var rms: Vector2 = p_analyzer.get_magnitude_for_frequency_range(freq_min, freq_max)
	var rms_value = (rms.x + rms.y) * 0.5
	var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))

	# convert to value around 0-1
	# capped becasue soundfont does not play well with higher values
	return pow(10, log_value / 10)
