extends Label

var _saving_label_timer: float = 0.0

func _ready() -> void:
	EventBus.saving_completed.connect(_on_saving_completed)
	EventBus.song_file_failed.connect(_on_song_file_failed)
	visible = false

func _process(delta: float) -> void:
	if visible:
		_saving_label_timer += delta
		if _saving_label_timer > 4.0:
			visible = false
			_saving_label_timer = 0.0

func _on_saving_completed(path: String) -> void:
	text = "Opgeslagen: " + path.get_file()
	visible = true
	_saving_label_timer = 0.0

func _on_song_file_failed(message: String) -> void:
	text = message
	visible = true
	_saving_label_timer = 0.0
