extends UIVisibilityListener

var hue: float = 0.0
var tween: Tween = null

func _process(_delta: float) -> void:
	hue += _delta
	self_modulate = Color.from_hsv(hue , 0.8, 1.0)
	#pulsate the scale of the pad a bit with a tween
	if tween == null or tween.is_running() == false:
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE *1.3, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
