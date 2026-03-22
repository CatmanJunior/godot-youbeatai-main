extends BaseButton

@export var my_group: DualSelectButtonGroup

func _ready() -> void:
	my_group.add_button(self )
