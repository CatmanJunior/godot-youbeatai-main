extends Node

var recorder: AudioEffectRecord
var capture: AudioEffectCapture
var recording: AudioStream
@export var audio_player: AudioStreamPlayer2D
var data: PackedVector2Array

@export var timer: Timer

var proccess = 0

var _synth = null

func _init() -> void:
	print("hoi")
	_synth = Synth.new()
	_synth.waveform = 2

func _ready():
	add_child(_synth)
	
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
		if index * (sample_rate / length) > 10000:
			continue
			
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
	
	timer.wait_time = recording.get_length() / len(data)
	print("recording length %f" % [recording.get_length()])
	print("recording data length %d" % [len(data)])
	print(data)

func play_recording():
	print(recording)
	audio_player.stream = recording
	
	_synth.pitch = data[proccess][0]
	_synth.volume = data[proccess][1] * 5
	_synth.start()
	timer.start()

func stop_playing():
	timer.stop()
	_synth.stop()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if audio_player.playing:
			audio_player.stop()
		else:
			audio_player.play()

func _on_timer_timeout():
	proccess = (proccess + 1) % len(data)
	_synth.pitch = data[proccess][0]
	_synth.volume = data[proccess][1] * 5
	
