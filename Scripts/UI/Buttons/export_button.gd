class_name ExportButton
extends Button

## song_mode: true | beat_mode: false
@export var mode: bool = false

func _ready():
    pressed.connect(on_pressed)

func on_pressed():
    print("export")

    EventBus.export_button_pressed.emit(mode)