extends Label

var _saving_label_timer: float = 0.0

func _ready() -> void:
	EventBus.done_saving.connect(_on_done_saving)
	visible = false

func _process(delta: float) -> void:
	if visible:
		_saving_label_timer += delta
		if _saving_label_timer > 4.0:
			visible = false
			_saving_label_timer = 0.0

func _on_done_saving(path: String) -> void:
	text = "Saved to: " + path.get_file()
	visible = true
	_saving_label_timer = 0.0