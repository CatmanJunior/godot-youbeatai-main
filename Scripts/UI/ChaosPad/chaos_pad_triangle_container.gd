extends Control
class_name TriangleContainer

@export var corners: Array[Control] = []
var tri: Array[Vector2] = []  # local-space triangle vertices

func _ready() -> void:
	EventBus.level_loaded.connect(level_loaded)

func level_loaded():
	if corners.size() >= 3:
		tri = [
			corners[0].position,
			corners[1].position,
			corners[2].position
		]
		queue_redraw()

func _draw() -> void:
	if not OS.is_debug_build():
		return
	if tri.size() < 3:
		return
	draw_colored_polygon(PackedVector2Array(tri), Color(0.2, 0.2, 0.3, 0.3))
	draw_polyline(PackedVector2Array(tri + [tri[0]]), Color.WHITE, 2.0)