extends Panel
@export var instruction_label: Label
@export var continue_button: Button
@export var title_label: Label
@export var amount_left_label: Label
@export var skip_tutorial_button: Button


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	skip_tutorial_button.pressed.connect(_on_skip_tutorial_pressed)
	EventBus.amount_left_text_requested.connect(_on_amount_left_text_requested)
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)

func _on_continue_pressed() -> void:
	EventBus.instruction_panel_continue_pressed.emit()

func _on_skip_tutorial_pressed() -> void:
	EventBus.skip_tutorial_requested.emit()

func _on_amount_left_text_requested(text: String) -> void:
	if amount_left_label:
		amount_left_label.text = text

func _on_ui_visibility_requested(element: int, vis: bool) -> void:
	if element == UIVisibilityListener.UIElement.AMOUNT_LEFT:
		if amount_left_label:
			amount_left_label.visible = vis