extends Control
class_name TriangleContainer

@export var corners : Array[Control] = []  # For visual reference, not used in math
# Define triangle vertices in local space
var tri: Array[Vector2] = []

func _ready() -> void:
	if corners.size() >= 3:
		tri = [corners[0].global_position, corners[1].global_position, corners[2].global_position]

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array(tri), Color(0.2, 0.2, 0.3, 0.5))
	draw_polyline(PackedVector2Array(tri + [tri[0]]), Color.WHITE, 2.0)

# --- Triangle math helpers ---

static func point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _cross(p - a, b - a)
	var d2 := _cross(p - b, c - b)
	var d3 := _cross(p - c, a - c)
	var has_neg := (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos := (d1 > 0) or (d2 > 0) or (d3 > 0)
	return not (has_neg and has_pos)

static func clamp_to_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	if point_in_triangle(p, a, b, c):
		return p
	# Find closest point on each edge, return nearest
	var candidates := [
		_closest_on_segment(p, a, b),
		_closest_on_segment(p, b, c),
		_closest_on_segment(p, c, a),
	]
	candidates.sort_custom(func(x, y): return p.distance_squared_to(x) < p.distance_squared_to(y))
	return candidates[0]

static func _closest_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
	return a + ab * t

static func _cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x
