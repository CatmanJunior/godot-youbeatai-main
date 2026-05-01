class_name ChaosPadCalculator
## Pure calculation helper for the chaos pad triangle.
## No scene-tree references — pass data in, get results out.

## Volume (in dB) applied when the knob is at maximum outer distance.
## 0.0 dB = full volume (knob on triangle edge), OUTER_VOLUME_FLOOR_DB at max range.
## Adjust to taste — more negative = more aggressive outer attenuation.
const OUTER_VOLUME_FLOOR_DB: float = -30.0


## Clamp [param knob_position] so it stays inside or within
## [param max_distance] pixels of the triangle defined by [param corners].
static func clamp_to_triangle_area(
	knob_position: Vector2,
	corners: Array[Vector2],
	max_distance: float
) -> Vector2:
	var a := corners[0]
	var b := corners[1]
	var c := corners[2]

	# If inside the triangle, allow free movement
	var weights := _barycentric_weights(knob_position, a, b, c)
	if _is_inside(weights):
		return knob_position

	# Find the closest edge and enforce max distance from it
	var dist_ab := _distance_to_segment(knob_position, a, b)
	var dist_bc := _distance_to_segment(knob_position, b, c)
	var dist_ca := _distance_to_segment(knob_position, c, a)

	var min_dist := minf(dist_ab, minf(dist_bc, dist_ca))

	if min_dist > max_distance:
		var closest: Vector2
		if min_dist == dist_ab:
			closest = _closest_point_on_segment(knob_position, a, b)
		elif min_dist == dist_bc:
			closest = _closest_point_on_segment(knob_position, b, c)
		else:
			closest = _closest_point_on_segment(knob_position, c, a)

		var dir := (knob_position - closest).normalized()
		knob_position = closest + dir * max_distance

	return knob_position


## Return a Dictionary with `master_volume` (float) and `weights` (Vector3)
## for the given knob position relative to the triangle.
static func calc_weights(
	knob_global_position: Vector2,
	corners: Array[Vector2],
	outer_triangle_size: float
) -> Dictionary:
	var p1 := corners[0]  # left
	var p2 := corners[1]  # top
	var p3 := corners[2]  # right

	var area_total := _sign_area(p1, p2, p3)
	if area_total == 0:
		return { "master_volume": 0.0, "weights": Vector3.ZERO }

	var u := _sign_area(knob_global_position, p2, p3) / area_total
	var v := _sign_area(p1, knob_global_position, p3) / area_total
	var w := _sign_area(p1, p2, knob_global_position) / area_total

	u = clamp(u, 0.0, 1.0)
	v = clamp(v, 0.0, 1.0)
	w = clamp(w, 0.0, 1.0)

	# Apply square-root curve before normalizing for equal-power blending.
	# This gives a more natural blend in the middle of the triangle instead
	# of a linear mix that can sound thin when multiple corners are active.
	u = sqrt(u)
	v = sqrt(v)
	w = sqrt(w)

	var total := u + v + w
	if total > 0:
		u /= total
		v /= total
		w /= total

	var calculation_weights := Vector3(u, v, w)

	# master_volume is returned as dB because set_volume_db() on TrackPlayerBase
	# feeds it directly to the audio bus (and stores it in track_data.master_volume).
	# When inside the triangle distance is 0 (full volume). Outside: square-law
	# taper landing at OUTER_VOLUME_FLOOR_DB at max outer distance.
	var bary := _barycentric_weights(knob_global_position, p1, p2, p3)
	var distance_from_triangle := 0.0
	if not _is_inside(bary):
		var closest := _closest_point_on_triangle(knob_global_position, p1, p2, p3)
		distance_from_triangle = knob_global_position.distance_to(closest)
	var linear_t := maxf(0.0, 1.0 - (distance_from_triangle / outer_triangle_size))
	var master_volume := lerpf(OUTER_VOLUME_FLOOR_DB, 0.0, linear_t * linear_t)

	return {
		"master_volume": master_volume,
		"weights": calculation_weights,
	}


# ── Private helpers ──────────────────────────────────────────────

static func _barycentric_weights(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> Vector3:
	var area_total := _sign_area(a, b, c)
	if area_total == 0:
		return Vector3.ZERO
	var u := _sign_area(p, b, c) / area_total
	var v := _sign_area(a, p, c) / area_total
	var w := _sign_area(a, b, p) / area_total
	return Vector3(u, v, w)


static func _is_inside(weights: Vector3) -> bool:
	return weights.x >= 0 and weights.y >= 0 and weights.z >= 0


static func _sign_area(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)) / 2.0


static func _distance_to_segment(p: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var ab := seg_b - seg_a
	var t : float = clamp((p - seg_a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return (p - (seg_a + ab * t)).length()


static func _closest_point_on_segment(p: Vector2, seg_a: Vector2, seg_b: Vector2) -> Vector2:
	var ab := seg_b - seg_a
	var t : float = clamp((p - seg_a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return seg_a + ab * t


static func _closest_point_on_triangle(point: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var best := point
	var best_dist := INF
	for edge in [[p1, p2], [p2, p3], [p3, p1]]:
		var cp := _closest_point_on_segment(point, edge[0], edge[1])
		var d := point.distance_to(cp)
		if d < best_dist:
			best_dist = d
			best = cp
	return best
