extends Line2D

func _process(delta: float) -> void:
	add_point(get_parent().global_position)
	if points.size() > 30:
		remove_point(0)
