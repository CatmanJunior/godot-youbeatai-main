extends HSlider

func _ready() -> void:
	var initial_threshold : float = value
	EventBus.recording_volume_threshold_changed.emit(initial_threshold)


func _value_changed(new_value: float) -> void:
	EventBus.recording_volume_threshold_changed.emit(new_value)

