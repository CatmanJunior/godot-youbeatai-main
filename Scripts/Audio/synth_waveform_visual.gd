class_name SynthWaveform
extends RefCounted
## Draws a circular waveform line from pre-computed sample data onto a Line2D node.

var line: Line2D
var points: int
var base_dist: int
var volume_dist: int
var reversed: bool
var offsets: PackedVector2Array = PackedVector2Array()

func _init(p_line: Line2D, p_points: int = 100, p_base_dist: int = 280, p_volume_dist: int = 28, p_reversed: bool = false):
	line = p_line
	points = p_points
	base_dist = p_base_dist
	volume_dist = p_volume_dist
	reversed = p_reversed


func update_line(samples: PackedFloat32Array, rate: float, length: float) -> void:
	if not line:
		return
	offsets = _compute_circular_offsets(samples, rate, length, points)
	_apply_offsets(offsets)


func _compute_circular_offsets(samples: PackedFloat32Array, rate: float, length: float, point_count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(point_count)
	for i in range(point_count):
		var volume_offset := 0.0
		if samples.size() > 0 and length > 0.0:
			var percentage := float(i) / float(point_count)
			var sample_idx := clampi(int(percentage * length * rate), 0, samples.size() - 1)
			volume_offset = abs(samples[sample_idx]) * volume_dist
		var angle := -PI / 2.0 + TAU * float(i) / float(point_count)
		var final_dist := (base_dist - volume_offset) if reversed else (base_dist + volume_offset)
		result[i] = Vector2(cos(angle), sin(angle)) * final_dist
	return result


func _apply_offsets(new_offsets) -> void:
	line.clear_points()
	for offset in new_offsets:
		line.add_point(offset)
