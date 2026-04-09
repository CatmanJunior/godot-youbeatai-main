extends Control
class_name TriangleContainer

@export var corners: Array[Control] = []
var tri: Array[Vector2] = []  # local-space triangle vertices

func _ready() -> void:
	# Defer so Control layout is resolved before reading positions
	await get_tree().process_frame
	if corners.size() >= 3:
		tri = [
			corners[0].position,
			corners[1].position,
			corners[2].position
		]
		queue_redraw()

func _draw() -> void:
	if tri.size() < 3:
		return
	draw_colored_polygon(PackedVector2Array(tri), Color(0.2, 0.2, 0.3, 0.3))
	draw_polyline(PackedVector2Array(tri + [tri[0]]), Color.WHITE, 2.0)