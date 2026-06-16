extends TextureRect


func _process(_delta):
    visible = GameState.microphone_volume > GameState.recording_volume_threshold