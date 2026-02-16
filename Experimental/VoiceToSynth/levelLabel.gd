extends Label


func _on_level_changed(level: float):
	text = "level: %f" % [level]
