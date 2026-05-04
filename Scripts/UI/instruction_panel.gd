extends Panel
@export var instruction_label: Label
@export var continue_button: Button
@export var title_label: Label
@export var amount_left_label: Label
@export var skip_tutorial_button: Button


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	skip_tutorial_button.pressed.connect(_on_skip_tutorial_pressed)

func _on_continue_pressed() -> void:
	EventBus.instruction_panel_continue_pressed.emit()

func _on_skip_tutorial_pressed() -> void:
	EventBus.skip_tutorial_requested.emit()