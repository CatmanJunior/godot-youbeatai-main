extends Line2D

var started := false

func _ready() -> void:
	await get_tree().process_frame
	clear_points()
	started = true


func _process(_delta: float) -> void:
	if not started:
		return
	add_point(get_parent().global_position)
	if points.size() > 50:
		remove_point(0)
