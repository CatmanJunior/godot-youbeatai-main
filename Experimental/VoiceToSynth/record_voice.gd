extends Node

@export var bpmManager: Node
@export var envelope: Envelope
@export var _synth: Synth

var recorder: AudioEffectRecord
var data: PackedVector3Array
var samples: PackedVector3Array
var proccess = 0
var start_record_time: float = 0

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Microphone")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	recorder = AudioServer.get_bus_effect(idx, 1) 

func _on_timer_timeout():
	if not _synth.playing:
		return
	
	proccess = (proccess + 1) % len(samples)
	var current = samples[proccess]
	_synth.pitch = current[0]
	_synth.volume = 0
	envelope.play()

func _on_envelope_level_changed(level: float):
	if not _synth.playing:
		return
	var rms_value = data[proccess][1]
	var log_value = 20.0 * (log( sqrt(rms_value) / 0.1) / log(10))
	_synth.volume = level * remap(log_value, -80, 10, 0, 1)

func on_microphone_input(volume: float, frequency: float):
	if not recorder.is_recording_active():
		return

	var time = Time.get_unix_time_from_system() - start_record_time
	data.push_back(Vector3(frequency, volume, time))
	
func start_recording():
	print("start recording")
	data.clear()
	start_record_time = Time.get_unix_time_from_system()

func stop_recording():
	print("stop recording")	
	print("recording data length %d" % [len(data)])
	
	var beatDuration = (60.0/bpmManager.bpm)/2.0
	samples = []
	for sample in data:
		if sample.z > len(samples) * beatDuration:
			samples.push_back(sample)
	
	print("samples(%d) \n %s" % [len(samples), samples])

func play_recording():
	proccess = 0
	_synth.pitch = data[proccess][0]
	_synth.volume = 0
	_synth.start()
	
	#initiate playback
	_on_timer_timeout()

func stop_playing():
	_synth.stop()
