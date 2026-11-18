class_name MicrophoneRecorder
extends Node

## Manages the microphone: live spectrum analysis (clap/stamp detection,
## volume level) AND audio recording via AudioEffectRecord.

@export var bus_name: String = BusNames.MICROPHONE_BUS
## Print one timing summary after each browser recording.
@export var web_audio_diagnostics_enabled: bool = true

static var analyzer: AudioEffectSpectrumAnalyzerInstance

var audio_stream_player: AudioStreamPlayer
var microphone: AudioStreamMicrophone

# Recording
var audio_effect_record: AudioEffectRecord
var _recording_started_usec: int = 0

func _ready() -> void:
	EventBus.recording_started.connect(_start_recording)
	EventBus.stop_recording_requested.connect(_stop_recording)
	EventBus.recording_cancelled.connect(_cancel_recording)
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

func _cancel_recording() -> void:
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)

# -- Recording -----------------------------------------------------------------
func _start_recording(_recording_data: RecordingData) -> void:
	if audio_effect_record:
		if OS.has_feature("web") and web_audio_diagnostics_enabled:
			_recording_started_usec = Time.get_ticks_usec()
		audio_effect_record.set_recording_active(true)
	else:
		push_error("Cannot start recording: no AudioEffectRecord found on bus '%s'." % bus_name)

func _stop_recording(recording_data: RecordingData) -> void:
	if audio_effect_record:
		var recording_stopped_usec: int = Time.get_ticks_usec() if OS.has_feature("web") and web_audio_diagnostics_enabled else 0
		audio_effect_record.set_recording_active(false)
		var audio: AudioStreamWAV = audio_effect_record.get_recording()
		if audio != null:
			# On Web, AudioEffectRecord tags the WAV with the output mix rate
			# (e.g. 48 kHz) while the captured samples come from the browser's
			# input AudioContext at its own rate. Playing back at the wrong
			# rate causes the recording to sound higher-pitched. Force the
			# WAV's mix rate to match the actual capture rate.
			if OS.has_feature("web"):
				var original_rate: int = audio.mix_rate
				var original_duration: float = audio.get_length()
				var input_rate: float = AudioServer.get_input_mix_rate()
				if input_rate > 0.0:
					audio.mix_rate = int(input_rate)
				if web_audio_diagnostics_enabled:
					var requested_duration: float = float(recording_stopped_usec - _recording_started_usec) / 1000000.0
					_log_web_audio_diagnostics(audio, input_rate, original_rate, original_duration, requested_duration)
		if recording_data:
			recording_data.audio_stream = audio  # Put audio ON the RecordingData
	EventBus.recording_stopped.emit(recording_data)


func _log_web_audio_diagnostics(audio: AudioStreamWAV, input_rate: float, original_rate: int, original_duration: float, requested_duration: float) -> void:
	var mix_rate: float = AudioServer.get_mix_rate()
	var output_latency_ms: float = AudioServer.get_output_latency() * 1000.0
	print("Web microphone diagnostics: input_rate=%d Hz, mix_rate=%d Hz, output_latency=%.1f ms, original_wav_rate=%d Hz, original_wav_duration=%.3f s, playback_wav_rate=%d Hz, playback_wav_duration=%.3f s, requested_capture=%.3f s, delay_correction=%.3f s" % [
		int(input_rate), int(mix_rate), output_latency_ms, original_rate, original_duration,
		audio.mix_rate, audio.get_length(), requested_duration, GameState.recording_delay_seconds
	])


# -- Helpers -------------------------------------------------------------------
static func get_magnitude(freq_min: float, freq_max: float, p_analyzer: AudioEffectSpectrumAnalyzerInstance = analyzer) -> float:
	var rms: Vector2 = p_analyzer.get_magnitude_for_frequency_range(freq_min, freq_max)
	var rms_value = (rms.x + rms.y) * 0.5
	var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))

	# convert to value around 0-1
	# capped becasue soundfont does not play well with higher values
	return pow(10, log_value / 10)
