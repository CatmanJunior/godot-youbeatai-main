extends Panel

@export var pro_button: Button

func _ready():
	pro_button.pressed.connect(_on_pro_button_pressed)

func _on_pro_button_pressed():
	SceneChanger.go_to_soundbank()
