extends Button

@export var fillTexture: TextureProgressBar

var toggled_on: bool = false

func _pressed() -> void:
	toggled_on = !toggled_on
	EventBus.recording_sample_button_toggled.emit(toggled_on)
	fillTexture.value = 1 if toggled_on else 0

func set_fill(value: float) -> void:
	fillTexture.value = value
