extends Node

var recorder: AudioEffectRecord
var capture: AudioEffectCapture
var recording: AudioStream
@export var audio_player: AudioStreamPlayer2D
var data: PackedVector2Array

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Microphone")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	recorder = AudioServer.get_bus_effect(idx, 1) 
	capture = AudioServer.get_bus_effect(idx, 0)
	print(recorder)

func _process(_delta):
	if not recorder.is_recording_active():
		return
		
	var frames = capture.get_frames_available()
	if frames == 0 :
		return
	var buffer := capture.get_buffer(frames)
	var amplitude := get_audio_amplitude(buffer)
	var frequency := get_peak_frequency(convertToMono(buffer))
	data.push_back(Vector2(frequency, amplitude))

func convertToMono(audio_data: PackedVector2Array)->PackedFloat32Array:
	var result: PackedFloat32Array = []
	
	for e in audio_data:
		result.push_back( (e.x + e.y)/2.0 )
		
	return result

func get_audio_amplitude(audio_data: PackedVector2Array)->float:
	var sum = 0

	for e in audio_data:
		sum += (abs(e.x) + abs(e.y)) / 2.0

	return sum / len(audio_data)

func get_peak_frequency(audio_data: PackedFloat32Array, sample_rate := 44100.0)->float:
	var fft: Array = FFT.reals( FFT.fft(audio_data) )
	var length := len(fft)
	
	var peak_index := 0
	var peak := 0.0
	
	for index in range(length):
		var e : float = fft[index]
		if e > peak:
			peak_index = index
			peak = e
	
	return peak_index * (sample_rate / length)
	
func start_recording():
	print("start recording")
	data.clear()
	recorder.set_recording_active(true)

func stop_recording():
	print("stop recording")
	recording = recorder.get_recording()
	recorder.set_recording_active(false)
	
	print(data)

func play_recording():
	print(recording)
	audio_player.stream = recording
	audio_player.play()

func stop_playing():
	audio_player.stop()
