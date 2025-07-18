extends Control

var recorder: AudioEffectRecord
@export var bpm: Node

func _ready():
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Microphone")
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.
	recorder = AudioServer.get_bus_effect(idx, 1) 

func start():
	recorder.set_recording_active(true)
	
func stop():
	recorder.set_recording_active(false)


func stop_playing():
	bpm.playing = false
	

func start_playing():
	bpm.playing = true
