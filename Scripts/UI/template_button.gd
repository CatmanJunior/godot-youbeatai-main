extends Button
class_name TemplateButton

var current_template: int = 4
var template_names: Array[String]:
	get:
		return TemplateManager.template_names

# --- Templates ---
@export_category("Templates")
@export var previous_template_button: Button
@export var next_template_button: Button
@export var tip_template_button: Button
@export var set_template_button: Button


func _ready():
	if current_template >= 0 and current_template < template_names.size():
		set_template_text(template_names[current_template])

	previous_template_button.pressed.connect(_previous_template)
	next_template_button.pressed.connect(_next_template)
	tip_template_button.pressed.connect(_toggle_show_template)
	set_template_button.pressed.connect(_set_template)

func _previous_template():
	current_template -= 1
	if current_template < 0:
		current_template = template_names.size() - 1
	set_template_text(template_names[current_template])

func _next_template():
	current_template += 1
	if current_template >= template_names.size():
		current_template = 0
	set_template_text(template_names[current_template])

func _toggle_show_template():
	GameState.show_template = not GameState.show_template

func _set_template():
	EventBus.template_set_requested.emit(current_template)

func set_template_text(file_name: String):
	text = file_name
