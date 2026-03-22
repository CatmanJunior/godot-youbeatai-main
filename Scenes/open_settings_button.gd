extends Button

func _ready():
    pressed.connect(_on_pressed)

func _on_pressed():
    EventBus.toggle_settings_menu_requested.emit()