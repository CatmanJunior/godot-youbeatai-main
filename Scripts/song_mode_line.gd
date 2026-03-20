extends MeshInstance2D

func _process(delta: float) -> void:
	visible = GameState.songModeActive
