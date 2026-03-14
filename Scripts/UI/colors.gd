extends Node

@export var colors: Array[Color] = [
	Color(0.9019608, 0.29411766, 0.5568628, 1),
	Color(0.972549, 0.52156866, 0.17254902, 1),
	Color(0.2627451, 0.79607844, 0.5294118, 1),
	Color(0.011764706, 0.8235294, 0.93333334, 1),
	Color(1, 1, 0, 1),
	Color(0.516666, 0, 1, 1),
	Color(0.61960787, 0.6117647, 0.8980392, 1)
]

var color_is_changing: bool = false
var colors_override: Array[Color] = []

func start_color_change(track_index: int, duration: float):
	color_is_changing = true

	var old_color = %UiManager.colors[track_index]
	var new_color = old_color.lightened(1.0)

	# brighten
	var elapsed = 0.0
	while elapsed < duration:
		var t = elapsed / duration
		var lerped_color = old_color.lerp(new_color, t)
		%UiManager.colors_override[track_index] = lerped_color

		# yield one frame
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# ensure final color is set
	%UiManager.colors_override[track_index] = new_color

	# darken
	elapsed = 0.0
	while elapsed < duration:
		var t = elapsed / duration
		var ct = %MixingManager.synth_mixing_line_color_curve.sample(t) if %MixingManager.synth_mixing_line_color_curve else t
		var lerped_color = new_color.lerp(old_color, ct)
		%UiManager.colors_override[track_index] = lerped_color

		# yield one frame
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# ensure final color is set
	%UiManager.colors_override[track_index] = old_color

	color_is_changing = false