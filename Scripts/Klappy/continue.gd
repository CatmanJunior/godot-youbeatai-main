extends Button

var _pulsating : bool = false
var _tween: Tween

func _ready()-> void:
	_pulsating = true
	

func _process(_delta: float) -> void:
	if _pulsating:
		if not _tween:
			pulse_animation()

func _pressed() -> void:
	EventBus.continue_button_pressed.emit()

func pulse_animation() -> void:
	#tween the button to pulsate every second
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await(_tween.finished)
	_tween = null
