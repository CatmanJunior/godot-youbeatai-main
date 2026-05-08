extends Panel

@export var pro_button: Button
@export var credits_button: Button
@export var back_button: Button
@export var tutorial_button: Button
@export var credits_panel: Panel

@export var fullscreen_button: Button

func _ready():
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	pro_button.pressed.connect(_on_pro_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) 
	fullscreen_button.pressed.connect(func(): 
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
		else:	
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) 
	)

func _on_tutorial_button_pressed():
	GameState.use_tutorial = true
	_switch_to_scene()

func _on_pro_button_pressed():
	GameState.use_tutorial = false
	_switch_to_scene()

func _switch_to_scene():
	TTSHelper.init()
	await get_tree().create_timer(0.1).timeout
	SceneChanger.go_to_soundbank()

func _on_credits_button_pressed():
	credits_panel.visible = true

func _on_back_button_pressed():
	credits_panel.visible = false
