extends Sprite2D

@export var id: int = 0
@export var button: Button

func _ready():
	button.button_up.connect(_on_press)

func _on_press():
	%MixingManager.synth_mixing_change_synth(id)
