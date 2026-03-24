extends Panel
class_name EmailPrompt

var do_mail: bool = true
var export_song: bool = false

@export var name_field: LineEdit
@export var mail_field: LineEdit
@export var mail_toggle: CheckButton
@export var mail_button: Button

func _ready():
	mail_button.pressed.connect(_on_mail_button_pressed)
	mail_toggle.toggled.connect(on_mail_toggle_changed)
	EventBus.export_button_pressed.connect(open_export_dialog)

func _on_mail_button_pressed():
	if not validate_form():
		name_field.modulate = Color.RED
		mail_field.modulate = Color.RED
		return
	
	EventBus.export_requested.emit(do_mail)
	close_export_dialog()
	
func on_mail_toggle_changed(value: bool):
	do_mail = value

func close_export_dialog():
	visible = false

func open_export_dialog(mode_export_song: bool):
	visible = true
	export_song = mode_export_song

func validate_form() -> bool:
	if name_field.text == "":
		return false

	if mail_field.text == "" and do_mail:
		return false

	GameState.export_name = name_field.text
	GameState.export_mail = mail_field.text
	return true
