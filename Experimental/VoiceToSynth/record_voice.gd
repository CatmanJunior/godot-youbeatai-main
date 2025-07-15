extends Node

@export var bpmManager: Node
@export var envelope: Envelope
@export var _synth: Synth

var recorder: AudioEffectRecord
var data: PackedVector3Array
@export var samples: Array[PackedVector3Array] = []
var current_layer: int = 0
var start_record_time: float = 0

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Microphone")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	recorder = AudioServer.get_bus_effect(idx, 1) 
	samples.resize(10)
	samples.fill(PackedVector3Array())
	
	bpmManager.OnBeatEvent.connect(_on_timer_timeout)
	bpmManager.OnPlayingChanged.connect(_on_playing_changed)

func _on_timer_timeout():
	if bpmManager.currentBeat == 0 and bpmManager.playing and _synth.playing == false:
		_synth.start()

	if bpmManager.currentBeat >= len(get_sample()):
		return
	
	var current = get_sample()[bpmManager.currentBeat]
	_synth.pitch = current[0]
	_synth.volume = 0
	envelope.play()

func _on_playing_changed(playing: bool):
	if playing:
		play_recording()
		return

	stop_playing()

func _on_envelope_level_changed(level: float):
	if bpmManager.currentBeat >= len(get_sample()):
		return
	var rms_value = get_sample()[bpmManager.currentBeat][1]
	var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))
	_synth.volume = level * remap(log_value, -80, 10, 0, 1)

func _on_current_layer_changed(layer: int):
	current_layer = layer

func on_microphone_input(volume: float, frequency: float):
	if not recorder.is_recording_active():
		return
	var time = Time.get_unix_time_from_system() - start_record_time
	data.push_back(Vector3(frequency, volume, time))
	
func start_recording():
	print("start recording")
	data.clear()
	get_sample().clear()
	_synth.stop()
	start_record_time = Time.get_unix_time_from_system()

func stop_recording():
	print("stop recording")	
	print("recording data length %d" % [len(data)])

	get_sample().clear()
	var beatDuration = (60.0/bpmManager.bpm)/4.0

	for sample in data:
		if sample.z > len(get_sample()) * beatDuration:
			get_sample().push_back(sample)
	
	get_sample().resize(bpmManager.amount_of_beats)	
	print("samples(%d) \n %s" % [len(get_sample()), get_sample()])

func play_recording():
	_synth.volume = 0
	_synth.start()
	
	#initiate playback
	_on_timer_timeout()

func stop_playing():
	_synth.stop()
	
func get_sample() -> PackedVector3Array:
	return samples[current_layer]
