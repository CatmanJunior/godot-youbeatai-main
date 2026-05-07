extends TextureRect


func _process(delta):
    visible = GameState.microphone_volume > GameState.recording_volume_threshold