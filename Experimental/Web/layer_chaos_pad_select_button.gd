extends Sprite2D

@export var id: int = 0
@export var button: Button

func _ready():
	button.button_up.connect(_on_press)

func _on_press():
	EventBus.synth_selected.emit(id)
