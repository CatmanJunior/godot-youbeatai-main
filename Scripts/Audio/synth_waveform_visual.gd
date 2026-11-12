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

func set_color(color: Color) -> void:
	if line:
		line.self_modulate = color


func _compute_circular_offsets(samples: PackedFloat32Array, rate: float, length: float, point_count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(point_count)
	for i in range(point_count):
		var volume_offset := 0.0
		if samples.size() > 0 and length > 0.0:
			var percentage := float(i) / float(point_count)
			var sample_idx := clampi(int(percentage * length * rate), 0, samples.size() - 1)
			
			# --- START SMOOTHING LOGIC ---
			var sum_abs_samples: float = 0.0
			var count: int = 0
			
			# Define a small window size (e.g., 3 samples: previous, current, next) 
			var window_size: int = 3
			
			for j in range(-window_size * 0.5, window_size, 1): # Iterates -1, 1, 3... (adjusting for window size)
				var neighbor_idx = sample_idx + j
				
				# Check if the neighbor index is within the bounds of the samples array
				if neighbor_idx >= 0 and neighbor_idx < samples.size():
					sum_abs_samples += (samples[neighbor_idx])
					count += 1
					
			# Calculate the average absolute value
			var average_abs_sample: float = sum_abs_samples / count
			volume_offset = average_abs_sample * volume_dist * 0.5

			# --- END SMOOTHING LOGIC ---
		var angle := -PI / 2.0 + TAU * float(i) / float(point_count)
		var final_dist := (base_dist - volume_offset) if reversed else (base_dist + volume_offset)
		result[i] = Vector2(cos(angle), sin(angle)) * final_dist
	return result


func _apply_offsets(new_offsets) -> void:
	line.clear_points()
	for offset in new_offsets:
		line.add_point(offset)
