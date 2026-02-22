extends Sprite2D

@export var ring: int = 0

var pressing: bool = false


var inside: bool:
	get: return is_pixel_opaque(get_local_mouse_position())

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and inside:
			pressing = !pressing
			if pressing:
				%AudioRecorder.start_recording(ring)
				_start_recording()
			else:
				%AudioRecorder.stop_recording()
				_stopRecording()

func _stopRecording():
	var fill: TextureProgressBar = get_child(0) as TextureProgressBar
	fill.value = 0
	pressing = false

func _start_recording():
	var fill: TextureProgressBar = get_child(0) as TextureProgressBar
	fill.value = 1
