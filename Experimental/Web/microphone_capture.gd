extends Node

const FftLib = preload("res://fft/Fft.gd")
const ComplexNum = preload("res://fft/Complex.gd")

@export var bus_name: String = "Microphone"
@export var clap_freq: float = 7000.0
@export var clap_threshold: float = 0.1
@export var stamp_freq: float = 30.0
@export var stamp_threshold: float = 0.005

var audio_effect_capture: AudioEffectCapture
var audio_stream_player: AudioStreamPlayer
var analyzer: AudioEffectSpectrumAnalyzerInstance
var microphone: AudioStreamMicrophone

var volume: float = 0.0
var frequency: float = 0.0
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
	audio_stream_player.finished.connect(func(): audio_stream_player.play())

	audio_stream_player.stream = microphone
	analyzer = AudioServer.get_bus_effect_instance(
		AudioServer.get_bus_index(bus_name), 2
	) as AudioEffectSpectrumAnalyzerInstance

	audio_stream_player.bus = bus_name
	audio_effect_capture = AudioServer.get_bus_effect(
		AudioServer.get_bus_index(bus_name), 0
	) as AudioEffectCapture

	audio_stream_player.play()

func process_audio_data():
	var frames = audio_effect_capture.get_frames_available()
	if frames > 0:
		var audio_data: PackedVector2Array = audio_effect_capture.get_buffer(frames)
		volume = _get_volume_from_audio_data(audio_data)
		frequency = _get_peak_frequency(_perform_fft(_convert_to_mono(audio_data)))
		EventBus.microphone_data_updated.emit(volume, frequency)

func _process(_delta: float):
	# process_audio_data()

	stamp_volume = _normalize_to_range(analyzer.get_magnitude_for_frequency_range(0.0, stamp_freq))
	clap_volume = _normalize_to_range(analyzer.get_magnitude_for_frequency_range(clap_freq, 20000.0))

func _normalize_to_range(rms: Vector2) -> float:
	var rms_value: float = (rms.x + rms.y) * 0.5
	var log_value: float = 20.0 * (log(sqrt(rms_value) / 0.1) / log(10))
	return pow(10.0, log_value / 10.0)

func _convert_to_mono(audio_data: PackedVector2Array) -> PackedFloat32Array:
	var mono_data := PackedFloat32Array()
	mono_data.resize(audio_data.size())
	for i in range(audio_data.size()):
		mono_data[i] = (audio_data[i].x + audio_data[i].y) / 2.0
	return mono_data

func _get_volume_from_audio_data(audio_data: PackedVector2Array) -> float:
	var sum: float = 0.0
	for sample in audio_data:
		var average_sample: float = (abs(sample.x) + abs(sample.y)) / 2.0
		sum += average_sample
	return sum / audio_data.size()

func _get_next_power_of_2(n: int) -> int:
	var power_of_2: int = 1
	while power_of_2 < n:
		power_of_2 <<= 1
	return power_of_2

func _perform_fft(audio_data: PackedFloat32Array) -> PackedFloat32Array:
	var N: int = audio_data.size()
	var next_power: int = _get_next_power_of_2(N)

	# Pad with zeros if not a power of 2
	if N != next_power:
		audio_data.resize(next_power)

	# Convert mono samples to Complex objects for Fft.gd
	var complex_data: Array = []
	complex_data.resize(audio_data.size())
	for i in range(audio_data.size()):
		complex_data[i] = ComplexNum.new(audio_data[i], 0.0)

	# Run FFT from the fft/ library
	complex_data = FftLib.fft(complex_data)
	
	# Extract magnitudes from the first half (positive frequencies)
	var magnitudes := PackedFloat32Array()
	
	@warning_ignore("integer_division")
	var half_size: int = audio_data.size() / 2
	
	magnitudes.resize(half_size)
	for i in range(half_size):
		var c: ComplexNum = complex_data[i]
		magnitudes[i] = sqrt(c.re * c.re + c.im * c.im)

	return magnitudes

func _get_peak_frequency(frequency_spectrum: PackedFloat32Array) -> float:
	var peak_index: int = 0
	var max_value: float = 0.0
	for i in range(frequency_spectrum.size()):
		if frequency_spectrum[i] > max_value:
			max_value = frequency_spectrum[i]
			peak_index = i
	var sample_rate: float = 44100.0
	return peak_index * (sample_rate / frequency_spectrum.size())
