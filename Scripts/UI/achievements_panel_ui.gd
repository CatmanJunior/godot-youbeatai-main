extends UIVisibilityListener
@export var instruction_label: Label
@export var title_label: Label
@export var continue_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.set_klappy_speech_bubble.connect(_on_klappy_speech_bubble)

func _on_klappy_speech_bubble(instruction: String, title: String, show_continue: bool) -> void:
	if instruction == "" and title == "":
		visible = false
		return
	visible = true
	if instruction_label:
		instruction_label.text = instruction
	if title_label:
		title_label.text = title
	if continue_button:
		continue_button.visible = show_continue


