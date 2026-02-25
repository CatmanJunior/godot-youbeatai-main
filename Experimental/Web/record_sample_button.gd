extends Sprite2D

signal button_on(ring: int)
signal button_off


@export var ring: int = 0

var pressing: bool = false
var down: bool = false

var inside: bool:
	get: return is_pixel_opaque(get_local_mouse_position())

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and inside and down:
			pressing = !pressing
			if pressing:
				emit_signal("button_on", ring)
				_start_recording()
			else:
				emit_signal("button_off")
				_stop_recording()
			down = false
			
		if event.pressed and inside:
			down = true
		else:
			down = false
			
func _stop_recording():
	var fill: TextureProgressBar = get_child(0) as TextureProgressBar
	fill.value = 0
	pressing = false

func _start_recording():
	var fill: TextureProgressBar = get_child(0) as TextureProgressBar
	fill.value = 1
