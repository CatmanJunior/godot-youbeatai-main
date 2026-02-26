extends LineEdit


func _ready():
	text_changed.connect(reset_color)

func reset_color(_new_text: String) -> void:
	modulate = Color.WHITE

func reset_from_toggle(value: bool) -> void:

	if value and text == "":
		modulate = Color.RED    

	if !value:
		modulate = Color.WHITE
