extends Node

@export var bus_name: String = "Microphone"
@export var clap_freq_min: float = 7000.0
@export var clap_threshold: float = 0.1
@export var stamp_freq_max: float = 150.0
@export var stamp_threshold: float = 0.005

var audio_stream_player: AudioStreamPlayer
var analyzer: AudioEffectSpectrumAnalyzerInstance
var microphone: AudioStreamMicrophone

var clap_volume: float = 0.0
var stamp_volume: float = 0.0

var is_clapping: bool:
	get: return clap_volume > clap_threshold and clap_volume > stamp_volume
var is_stamping: bool:
	get: return stamp_volume > stamp_threshold and stamp_volume > clap_volume

func _ready():
	microphone = AudioStreamMicrophone.new()
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	audio_stream_player.stream = microphone
	audio_stream_player.bus = bus_name

	var bus_index: int = AudioServer.get_bus_index(bus_name)
	var spectrum := AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(bus_index, spectrum)

	analyzer = AudioServer.get_bus_effect_instance(
		bus_index, AudioServer.get_bus_effect_count(bus_index) - 1
	) as AudioEffectSpectrumAnalyzerInstance

	assert(analyzer != null, "Could not find AudioEffectSpectrumAnalyzerInstance on bus: " + bus_name)

	audio_stream_player.play()

func _process(_delta: float):
	stamp_volume = _get_magnitude(0.0, stamp_freq_max)
	clap_volume = _get_magnitude(clap_freq_min, 20000.0)
	EventBus.microphone_volume = _get_magnitude(0.0, 20000.0)

func _get_magnitude(freq_min: float, freq_max: float) -> float:
	var rms: Vector2 = analyzer.get_magnitude_for_frequency_range(freq_min, freq_max)
	return (rms.x + rms.y) * 0.5

func get_microphone_volume() -> float:
	# This can be used by other scripts to get the current microphone volume level
	return _get_magnitude(0.0, 20000.0)
	
