class_name SynthVoiceRecorder

## Voice-over recording policy: adds a configurable delay before start/stop,
## ducks the SubMaster bus during recording, and tracks arm/finished state.
## Delegates actual mic capture to MicrophoneRecorder (%MicrophoneCapture).

signal recording_started
signal recording_stopped(recorded_audio: AudioStream)

var mic: MicrophoneRecorder

var should_record: bool = false
var finished: bool = false

var recording: bool:
	get: return mic.recording if mic else false

var recording_timer: float:
	get: return mic.recording_timer if mic else 0.0

var _scene_tree: SceneTree
var _get_delay: float


func _init(scene_tree: SceneTree, get_delay: float, microphone_recorder: MicrophoneRecorder = null) -> void:
	_scene_tree = scene_tree
	_get_delay = get_delay
	mic = microphone_recorder


func arm() -> void:
	should_record = true


func cancel() -> void:
	should_record = false


func start() -> void:
	var delay: float = _get_delay
	await _scene_tree.create_timer(delay).timeout
	mic.start_recording()
	print("recording started")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), linear_to_db(0.1))
	recording_started.emit()


func stop() -> void:
	var delay: float = _get_delay
	await _scene_tree.create_timer(delay).timeout
	var recorded_audio := mic.stop_recording()
	print("recording stopped")
	should_record = false
	finished = true
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), 0.0)
	recording_stopped.emit(recorded_audio)
