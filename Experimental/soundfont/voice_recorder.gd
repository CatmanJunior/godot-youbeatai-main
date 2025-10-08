extends Node
class_name VoiceRecorder

signal done_recording(data: PackedVector3Array)

var data: PackedVector3Array = []
var recording_start = 0
var recorder
var recording: bool = false

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Microphone")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	recorder = AudioServer.get_bus_effect(idx, 1) 

func on_microphone_input(volume: float, frequency: float):
	if not recording:
		return

	var time = Time.get_unix_time_from_system() - recording_start
	data.push_back(Vector3(frequency, volume, time))
	
func start_recording():
	print("start generic voice recorder")
	data.clear()
	recording_start = Time.get_unix_time_from_system()
	recording = true

func stop_recording():
	print("stop generic voice recorder")
	recording = false
	done_recording.emit(data)
