extends PointLight2D

@export var hLSlider: Slider
@export var pDSlider: Slider

func _on_klappy_high_lowpass_value_changed(value: float) -> void:
	if value < 0.5:
		color = "yellow"
	elif value > 0.5:
		color = "blue"


func _on_klappy_phaser_distortion_value_changed(value: float) -> void:
	if value < 0.5:
		color = "green"
	elif value > 0.5:
		color = "red"
