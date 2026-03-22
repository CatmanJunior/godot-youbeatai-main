class_name MicrophoneRecorder
extends Node

## Manages the microphone: live spectrum analysis (clap/stamp detection,
## volume level) AND audio recording via AudioEffectRecord.
## Lives in the scene tree as %MicrophoneCapture.

@export var bus_name: String = "Microphone"
@export var clap_freq_min: float = 7000.0
@export var clap_threshold: float = 0.1
@export var stamp_freq_max: float = 150.0
@export var stamp_threshold: float = 0.005

var audio_stream_player: AudioStreamPlayer
var analyzer: AudioEffectSpectrumAnalyzerInstance
var microphone: AudioStreamMicrophone

# Recording
var audio_effect_record: AudioEffectRecord
var recording: bool = false
var recording_timer: float = 0.0

# Live analysis
var clap_volume: float = 0.0
var stamp_volume: float = 0.0

var is_clapping: bool:
	get: return clap_volume > clap_threshold and clap_volume > stamp_volume
var is_stamping: bool:
	get: return stamp_volume > stamp_threshold and stamp_volume > clap_volume

func _ready():
	EventBus.start_recording_requested.connect(_start_recording)
	EventBus.stop_recording_requested.connect(_stop_recording)
	microphone = AudioStreamMicrophone.new()
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	audio_stream_player.stream = microphone
	audio_stream_player.bus = bus_name

	var bus_index: int = AudioServer.get_bus_index(bus_name)

	# Spectrum analyzer (appended as last effect)
	var spectrum := AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(bus_index, spectrum)

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

func _process(delta: float):
	# Live volume analysis
	stamp_volume = _get_magnitude(0.0, stamp_freq_max)
	clap_volume = _get_magnitude(clap_freq_min, 20000.0)
	GameState.microphone_volume = _get_magnitude(0.0, 20000.0)

	# Recording timer
	if recording:
		recording_timer += delta
	else:
		recording_timer = 0.0


# -- Recording -----------------------------------------------------------------

func _start_recording() -> void:
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)
		recording = true
		EventBus.recording_started.emit()
	else:
		push_warning("Cannot start recording: no AudioEffectRecord found on %s bus, effect 1" % bus_name)

func _stop_recording() -> void:
	var recorded_audio: AudioStream = null
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		recorded_audio = audio_effect_record.get_recording()
	recording = false
	EventBus.recording_stopped.emit(recorded_audio)

# -- Helpers -------------------------------------------------------------------

func _get_magnitude(freq_min: float, freq_max: float) -> float:
	var rms: Vector2 = analyzer.get_magnitude_for_frequency_range(freq_min, freq_max)
	return (rms.x + rms.y) * 0.5

func get_microphone_volume() -> float:
	return _get_magnitude(0.0, 20000.0)
