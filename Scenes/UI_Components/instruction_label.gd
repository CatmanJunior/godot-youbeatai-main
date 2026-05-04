extends Label

func _ready() -> void:
    EventBus.tutorial_instruction_text_requested.connect(_on_tutorial_instruction_text_requested)

func _on_tutorial_instruction_text_requested(instruction_text: String) -> void:
    text = instruction_text