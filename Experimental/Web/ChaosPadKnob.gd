extends Sprite2D

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var cached_on_mouse_up_action: Callable = Callable()

var ui_manager: Node

func _ready():
	ui_manager = get_node("/root/scene/Managers/UiManager")

func sub_to_on_mouse_up(action: Callable) -> void:
	cached_on_mouse_up_action = action

func _input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton:
		var mouse_button_event = input_event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed:
				var chaospad_opaque = ui_manager.chaos_pad_triangle_sprite.is_pixel_opaque(ui_manager.chaos_pad_triangle_sprite.get_local_mouse_position())
				var knob_opaque = is_pixel_opaque(get_local_mouse_position())
				if knob_opaque or chaospad_opaque:
					dragging = true
					drag_offset = global_position - mouse_button_event.position
			else:
				dragging = false
				var chaospad_opaque = ui_manager.chaos_pad_triangle_sprite.is_pixel_opaque(ui_manager.chaos_pad_triangle_sprite.get_local_mouse_position())
				var knob_opaque = is_pixel_opaque(get_local_mouse_position())
				if knob_opaque or chaospad_opaque:
					cached_on_mouse_up_action.call()
	
	if input_event is InputEventMouseMotion and dragging:
		var mouse_motion_event = input_event as InputEventMouseMotion
		new_position(mouse_motion_event.position + drag_offset)

func new_position(position: Vector2) -> void:
	# triangle edges
	var corners: Array[Node2D] = ui_manager.corners
	var a: Vector2 = corners[0].global_position
	var b: Vector2 = corners[1].global_position
	var c: Vector2 = corners[2].global_position
	
	# free movement inside triangle
	var weights = ui_manager.get_barycentric_weights(position, a, b, c)
	if ui_manager.is_inside_triangle(weights):
		global_position = position
		return
	
	# max dist from triangle
	var maxdist: float = ui_manager.outer_triangle_size
	
	# distance from point to segment
	var distance_to_segment = func(p: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
		var ab: Vector2 = seg_b - seg_a
		var t: float = (p - seg_a).dot(ab) / ab.length_squared()
		t = clamp(t, 0.0, 1.0)
		var projection: Vector2 = seg_a + ab * t
		return (p - projection).length()
	
	# closest point on segment
	var closest_point_on_segment = func(p: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
		var ab: Vector2 = seg_b - seg_a
		var t: float = (p - seg_a).dot(ab) / ab.length_squared()
		t = clamp(t, 0.0, 1.0)
		return seg_a + ab * t
	
	# check distance from each edge
	var dist_ab: float = distance_to_segment.call(position, a, b)
	var dist_bc: float = distance_to_segment.call(position, b, c)
	var dist_ca: float = distance_to_segment.call(position, c, a)
	
	var min_dist: float = minf(dist_ab, minf(dist_bc, dist_ca))
	
	# if the position is too far from the closest edge, move it closer
	if min_dist > maxdist:
		var closest_point: Vector2 = position
		if min_dist == dist_ab:
			closest_point = closest_point_on_segment.call(position, a, b)
		elif min_dist == dist_bc:
			closest_point = closest_point_on_segment.call(position, b, c)
		elif min_dist == dist_ca:
			closest_point = closest_point_on_segment.call(position, c, a)
		
		var dir: Vector2 = (position - closest_point).normalized()
		position = closest_point + dir * maxdist
	
	global_position = position
