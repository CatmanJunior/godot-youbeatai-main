extends Node

var up_pressed: bool = false
var up_pressed_lastframe: bool = false
var dn_pressed: bool = false
var dn_pressed_lastframe: bool = false
var space_pressed_lastframe: bool = false
var enter_pressed_lastframe: bool = false
var f11_pressed: bool = false
var f11_pressed_lastframe: bool = false

# Ring key tracking (A, S, D, F)
var a_pressed: bool = false
var a_pressed_lastframe: bool = false
var s_pressed: bool = false
var s_pressed_lastframe: bool = false
var d_pressed: bool = false
var d_pressed_lastframe: bool = false
var f_pressed: bool = false
var f_pressed_lastframe: bool = false


func _process(_delta: float):
	_handle_arrow_keys()
	_handle_space_key()
	_handle_enter_key()
	_handle_fullscreen_toggle()
	_handle_ring_keys()
	_handle_debug_shortcuts()

func _handle_arrow_keys():
	up_pressed_lastframe = up_pressed
	up_pressed = Input.is_key_pressed(KEY_UP)
	if up_pressed and up_pressed != up_pressed_lastframe:
		EventBus.bpm_up_requested.emit(5)
	
	dn_pressed_lastframe = dn_pressed
	dn_pressed = Input.is_key_pressed(KEY_DOWN)
	if dn_pressed and dn_pressed != dn_pressed_lastframe:
		EventBus.bpm_down_requested.emit(5)

func _handle_space_key():
	var space_pressed = Input.is_key_pressed(KEY_SPACE)
	if space_pressed and not space_pressed_lastframe:
		EventBus.play_pause_toggle_requested.emit()
	space_pressed_lastframe = space_pressed

func _handle_enter_key():
	var is_enter_key_pressed = Input.is_key_pressed(KEY_ENTER)
	if is_enter_key_pressed and not enter_pressed_lastframe:
		EventBus.enter_pressed.emit()
	enter_pressed_lastframe = is_enter_key_pressed

func _handle_fullscreen_toggle():
	f11_pressed_lastframe = f11_pressed
	f11_pressed = Input.is_key_pressed(KEY_F11)
	if f11_pressed and f11_pressed != f11_pressed_lastframe:
		EventBus.fullscreen_toggle_requested.emit()
		_toggle_fullscreen()

func _toggle_fullscreen():
	var window = get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN

func _handle_ring_keys():
	# A key - Ring 0
	a_pressed_lastframe = a_pressed
	a_pressed = Input.is_key_pressed(KEY_A)
	if a_pressed and a_pressed != a_pressed_lastframe:
		EventBus.ring_0_pressed.emit()
	
	# S key - Ring 1
	s_pressed_lastframe = s_pressed
	s_pressed = Input.is_key_pressed(KEY_S)
	if s_pressed and s_pressed != s_pressed_lastframe:
		EventBus.ring_1_pressed.emit()
	
	# D key - Ring 2
	d_pressed_lastframe = d_pressed
	d_pressed = Input.is_key_pressed(KEY_D)
	if d_pressed and d_pressed != d_pressed_lastframe:
		EventBus.ring_2_pressed.emit()
	
	# F key - Ring 3
	f_pressed_lastframe = f_pressed
	f_pressed = Input.is_key_pressed(KEY_F)
	if f_pressed and f_pressed != f_pressed_lastframe:
		EventBus.ring_3_pressed.emit()

func _handle_debug_shortcuts():
	# Debug BPM shortcuts
	if not Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(900)
	
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(4000)
	
	if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_F6):
		EventBus.bpm_set_requested.emit(90)
