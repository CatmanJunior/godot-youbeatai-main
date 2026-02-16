extends Line2D

func _process(_delta: float) -> void:
	add_point(get_parent().global_position)
	if points.size() > 50:
		remove_point(0)
