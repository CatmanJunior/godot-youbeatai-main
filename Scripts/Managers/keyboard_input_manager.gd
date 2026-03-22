extends Node

## Tracks key state across frames and emits EventBus signals on key-down edges.
## Uses a dictionary to eliminate the repetitive per-key boolean tracking pattern.

# Maps Godot key constants to a dictionary of {pressed, last_frame}
var _key_states: Dictionary = {}

# Key → callable mapping for single-fire key-down actions
var _key_actions: Dictionary = {}

func _ready() -> void:
	_key_actions = {
		KEY_UP: func(): EventBus.bpm_up_requested.emit(5),
		KEY_DOWN: func(): EventBus.bpm_down_requested.emit(5),
		KEY_SPACE: func(): EventBus.play_pause_toggle_requested.emit(),
		KEY_ENTER: func(): EventBus.enter_pressed.emit(),
		KEY_F11: func(): EventBus.fullscreen_toggle_requested.emit(),
		KEY_A: func(): EventBus.ring_key_pressed.emit(0),
		KEY_S: func(): EventBus.ring_key_pressed.emit(1),
		KEY_D: func(): EventBus.ring_key_pressed.emit(2),
		KEY_F: func(): EventBus.ring_key_pressed.emit(3),
	}

	# Initialize state tracking for all managed keys with current state
	# to avoid false key-down events on the first frame
	for key in _key_actions:
		_key_states[key] = Input.is_key_pressed(key)

func _process(_delta: float) -> void:
	_poll_keys()
	_handle_debug_shortcuts()

func _poll_keys() -> void:
	for key in _key_actions:
		var was_pressed: bool = _key_states[key]
		var is_pressed: bool = Input.is_key_pressed(key)
		_key_states[key] = is_pressed

		if is_pressed and not was_pressed:
			_key_actions[key].call()


func _handle_debug_shortcuts() -> void:
	if not Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(900)

	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(4000)

	if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(90)
