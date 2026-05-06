extends TextureRect

func _process(_delta: float) -> void:
	visible = GameState.song_mode_active
	
