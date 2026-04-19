class_name MicrophoneRecorder
extends Node

## Manages the microphone: live spectrum analysis (clap/stamp detection,
## volume level) AND audio recording via AudioEffectRecord.

@export var bus_name: String = "Microphone"

var audio_stream_player: AudioStreamPlayer
var analyzer: AudioEffectSpectrumAnalyzerInstance
var microphone: AudioStreamMicrophone

# Recording
var audio_effect_record: AudioEffectRecord

func _ready():
	EventBus.recording_started.connect(_start_recording)
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

func _process(_delta: float):
	GameState.microphone_volume = _get_magnitude(0.0, 20000.0)

# -- Recording -----------------------------------------------------------------
func _start_recording(_recording_data: RecordingData) -> void:
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)
	else:
		push_error("Cannot start recording: no AudioEffectRecord found on bus '%s'." % bus_name)

func _stop_recording(recording_data: RecordingData) -> void:
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		var audio = audio_effect_record.get_recording()
		if recording_data:
			recording_data.audio_stream = audio  # Put audio ON the RecordingData
	EventBus.recording_stopped.emit(recording_data)

# -- Helpers -------------------------------------------------------------------
func _get_magnitude(freq_min: float, freq_max: float) -> float:
	var rms: Vector2 = analyzer.get_magnitude_for_frequency_range(freq_min, freq_max)
	return (rms.x + rms.y) * 0.5
