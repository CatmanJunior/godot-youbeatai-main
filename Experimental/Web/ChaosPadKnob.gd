extends Sprite2D

signal on_mouse_up(master_volume: float, weights: Vector3)


var corners: Array[Node2D] = [] # left, top, right
var outer_triangle_size: float = 60.0


var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var ui_manager: Node
var mixing_manager: Node
var setting_panel: Panel

func _ready():
	ui_manager = get_node("/root/scene/Managers/UiManager")
	mixing_manager = get_node("/root/scene/Managers/GameManager/MixingManager")
	setting_panel = get_node("/root/scene/UserInterface/SettingsPanel")
	corners = ui_manager.corners


func _input(input_event: InputEvent) -> void:
	if setting_panel.visible:
		return
	
	if input_event is InputEventMouseMotion and dragging:
		var mouse_motion_event = input_event as InputEventMouseMotion
		var new_pos = mouse_motion_event.position + drag_offset
		# Update knob position
		var pos = new_position(new_pos)
		#set position
		global_position = pos

	if input_event is not InputEventMouseButton:
		return
	
	var mouse_button_event = input_event as InputEventMouseButton
	if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var chaospad_opaque = ui_manager.chaos_pad_triangle_sprite.is_pixel_opaque(ui_manager.chaos_pad_triangle_sprite.get_local_mouse_position())
	var knob_opaque = is_pixel_opaque(get_local_mouse_position())
	if mouse_button_event.pressed:
		if knob_opaque or chaospad_opaque:
			dragging = true
			drag_offset = global_position - mouse_button_event.position
	else:
		dragging = false
		if knob_opaque or chaospad_opaque:
			var result = get_weights_for_position()
			EventBus.mixing_weights_changed.emit(result.master_volume, result.weights)


func new_position(knobPosition: Vector2) -> Vector2:
	# triangle edges
	var a: Vector2 = corners[0].global_position
	var b: Vector2 = corners[1].global_position
	var c: Vector2 = corners[2].global_position
	
	# free movement inside triangle
	var weights = get_weights_for_position().weights
	if is_inside_triangle(weights):
		global_position = knobPosition
		return knobPosition
	
	# max dist from triangle
	var maxdist: float = mixing_manager.outer_triangle_size
	
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
	var dist_ab: float = distance_to_segment.call(knobPosition, a, b)
	var dist_bc: float = distance_to_segment.call(knobPosition, b, c)
	var dist_ca: float = distance_to_segment.call(knobPosition, c, a)
	
	var min_dist: float = minf(dist_ab, minf(dist_bc, dist_ca))
	
	# if the position is too far from the closest edge, move it closer
	if min_dist > maxdist:
		var closest_point: Vector2 = knobPosition
		if min_dist == dist_ab:
			closest_point = closest_point_on_segment.call(knobPosition, a, b)
		elif min_dist == dist_bc:
			closest_point = closest_point_on_segment.call(knobPosition, b, c)
		elif min_dist == dist_ca:
			closest_point = closest_point_on_segment.call(knobPosition, c, a)
		
		var dir: Vector2 = (knobPosition - closest_point).normalized()
		knobPosition = closest_point + dir * maxdist
	
	global_position = knobPosition
	return knobPosition

func get_weights_for_position() -> Dictionary:
	"""Calculate weights based on knob position in triangle"""
	
	# Get triangle corners
	var p1 = corners[0].global_position # left
	var p2 = corners[1].global_position # top
	var p3 = corners[2].global_position # right
	
	# Calculate barycentric coordinates using the area method
	var area_total = sign_area(p1, p2, p3)
	if area_total == 0:
		return {"master_volume": 0.0, "weights": Vector3.ZERO}
	
	var area1 = sign_area(global_position, p2, p3)
	var area2 = sign_area(p1, global_position, p3)
	var area3 = sign_area(p1, p2, global_position)
	
	var u = area1 / area_total
	var v = area2 / area_total
	var w = area3 / area_total
	
	# Clamp weights to [0, 1] for positions outside triangle
	u = clamp(u, 0.0, 1.0)
	v = clamp(v, 0.0, 1.0)
	w = clamp(w, 0.0, 1.0)
	
	# Normalize weights
	var total = u + v + w
	if total > 0:
		u /= total
		v /= total
		w /= total
	
	var calc_weights = Vector3(u, v, w)
	
	# Calculate master volume based on distance from triangle
	var closest_point = get_closest_point_on_triangle(global_position, p1, p2, p3)
	var distance_from_triangle = global_position.distance_to(closest_point)
	
	# Master volume decreases as we move away from the triangle
	var master_volume = max(0.0, 1.0 - (distance_from_triangle / outer_triangle_size))
	
	return {
		"master_volume": master_volume,
		"weights": calc_weights
	}

func is_inside_triangle(triangleWeights: Vector3) -> bool:
	"""Check if the position is inside the triangle based on weights"""
	return triangleWeights.x >= 0 and triangleWeights.y >= 0 and triangleWeights.z >= 0

func sign_area(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	"""Calculate signed area of triangle (used for barycentric coordinates)"""
	return (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)) / 2.0

func get_closest_point_on_triangle(point: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	"""Find the closest point on the triangle to the given point"""
	var closest = point
	var min_dist = INF
	
	# Check closest point on each edge
	var edges = [[p1, p2], [p2, p3], [p3, p1]]
	for edge in edges:
		var closest_on_edge = get_closest_point_on_segment(point, edge[0], edge[1])
		var dist = point.distance_to(closest_on_edge)
		if dist < min_dist:
			min_dist = dist
			closest = closest_on_edge
	
	return closest

func get_closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	"""Find the closest point on a line segment to the given point"""
	var segment = segment_end - segment_start
	var to_point = point - segment_start
	var t = max(0.0, min(1.0, to_point.dot(segment) / segment.dot(segment)))
	return segment_start + t * segment
