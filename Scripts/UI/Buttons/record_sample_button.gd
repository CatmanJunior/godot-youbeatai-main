extends Button
class_name RecordSampleButton
@export var fillTexture: TextureProgressBar

var toggled_on: bool = false

func _pressed() -> void:
	toggled_on = !toggled_on

	EventBus.record_button_toggled.emit(toggled_on)
	fillTexture.value = 1 if toggled_on else 0

func update_button(progressRatio: float, color: Color = Color.RED) -> void:
	if progressRatio >= 1.0:
		toggled_on = false
		fillTexture.value = 0
	else:
		fillTexture.value = 1 - progressRatio

	fillTexture.tint_progress = color
