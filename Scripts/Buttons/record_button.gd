extends Sprite2D

@export var id: int = 0

var inside: bool:
	get: return is_pixel_opaque(get_local_mouse_position())

var original_c: Color
var hover_c: Color
var pressed_c: Color

var pressed: bool = false

func _ready():
	original_c = self_modulate
	hover_c = original_c.lightened(0.2)
	pressed_c = Color(1, 0, 0, 1)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_released():
			if inside:
				_on_pressed()

func _process(_delta: float):
	if pressed:
		self_modulate = pressed_c
	elif inside:
		self_modulate = hover_c
	else:
		self_modulate = original_c

func _on_pressed():
	pass  # on click
