extends TextureRect


func _process(_delta):
    rotation_degrees = GameState.bar_progress * 360.0