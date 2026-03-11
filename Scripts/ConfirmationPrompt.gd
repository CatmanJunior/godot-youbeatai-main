extends Panel

@export var confirmation_button_agree: Button
@export var confirmation_button_cancel: Button

var _cached_agree_action: Callable = Callable()

func open(agree_action: Callable) -> void:
	# show confirmation prompt
	position = Vector2(-224.0, -112.0)

	# set agree button action
	_cached_agree_action = agree_action
	confirmation_button_agree.button_up.connect(_cached_agree_action)
	confirmation_button_agree.button_up.connect(close)

	# set disagree button
	confirmation_button_cancel.button_up.connect(close)


func close() -> void:
	# set aside confirmation prompt
	position = Vector2(-224.0, -2000.0)

	# reset agree button action
	confirmation_button_agree.button_up.disconnect(close)
	confirmation_button_agree.button_up.disconnect(_cached_agree_action)
	_cached_agree_action = Callable()

	# reset disagree button
	confirmation_button_cancel.button_up.disconnect(close)
