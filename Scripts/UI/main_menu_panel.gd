extends Panel

@export var pro_button: Button
@export var credits_button: Button
@export var back_button: Button

@export var credits_panel: Panel

func _ready():
	pro_button.pressed.connect(_on_pro_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_pro_button_pressed():
	if OS.has_feature("web"):
		# try to speak, it wont play but will enable the tts
		TTSHelper.speak("test")

	await get_tree().create_timer(0.1).timeout
	SceneChanger.go_to_soundbank()

func _on_credits_button_pressed():
	credits_panel.visible = true

func _on_back_button_pressed():
	credits_panel.visible = false
