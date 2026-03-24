extends Sprite2D
@export var corners: Array[Control] = [] # left, top, right
@export var chaos_pad_ui: ChaosPadUI
var outer_triangle_size: float = 60.0

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var mixing_manager: Node

func _ready():
	pass




func _get_corner_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for c in corners:
		positions.append(c.global_position)
	return positions


func _input(input_event: InputEvent) -> void:


	if input_event is InputEventMouseMotion and dragging:
		var mouse_motion_event = input_event as InputEventMouseMotion
		var new_pos = mouse_motion_event.position + drag_offset
		var max_dist: float = chaos_pad_ui.outer_triangle_size
		var pos = ChaosPadCalculator.clamp_to_triangle_area(new_pos, _get_corner_positions(), max_dist)
		global_position = pos
		# Emit dragging data via EventBus
		var result = ChaosPadCalculator.calc_weights(global_position, _get_corner_positions(), outer_triangle_size)
		EventBus.chaos_pad_dragging.emit(global_position, result.master_volume, result.weights)

	if input_event is not InputEventMouseButton:
		return

	var mouse_button_event = input_event as InputEventMouseButton
	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var chaospad_opaque = chaos_pad_ui.chaos_pad_triangle_sprite.is_pixel_opaque(chaos_pad_ui.chaos_pad_triangle_sprite.get_local_mouse_position())
	var knob_opaque = is_pixel_opaque(get_local_mouse_position())
	if mouse_button_event.pressed:
		if knob_opaque or chaospad_opaque:
			dragging = true
			drag_offset = global_position - mouse_button_event.position
	else:
		dragging = false
		if knob_opaque or chaospad_opaque:
			var result = ChaosPadCalculator.calc_weights(global_position, _get_corner_positions(), outer_triangle_size)
			EventBus.chaos_pad_released.emit(result.master_volume, result.weights)
			EventBus.mixing_weights_changed.emit(result.master_volume, result.weights)
