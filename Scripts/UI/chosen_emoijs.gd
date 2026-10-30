extends Label


func _ready() -> void:
	EventBus.song_loaded.connect(_update_emojis)
	_update_emojis()


func _update_emojis() -> void:
	text = SongState.chosen_emoij