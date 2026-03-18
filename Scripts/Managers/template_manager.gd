extends Node

@export var template_button: Button
@export var left_template_button: Button
@export var right_template_button: Button
@export var show_template_button: Button
@export var set_template_button: Button

var names: Array[String] = []
var contents: Array[String] = []
var actives: Array = []  # Array of Array[bool] (row per ring)

var current_template: int = 4
var show_template: bool = false

func _ready():
	left_template_button.pressed.connect(_previous_template)
	right_template_button.pressed.connect(_next_template)
	show_template_button.pressed.connect(_toggle_show_template)
	set_template_button.pressed.connect(_set_template)

	read_templates()

func _process(_delta: float) -> void:
	if current_template >= 0 and current_template < names.size():
		var file_name = names[current_template]
		template_button.text = file_name.left(file_name.length() - 4)  # Strip ".txt"

func read_templates():
	var result = _load_text_files_in_directory("Resources/Templates")
	names = result.names
	contents = result.contents
	actives = result.actives

func _load_text_files_in_directory(folder: String) -> Dictionary:
	var folder_path = "res://%s/" % folder
	var dir = DirAccess.open(folder_path)

	var temp_names: Array[String] = []
	var temp_contents: Array[String] = []
	var temp_actives: Array = []

	if dir == null:
		push_error("Could not open directory: %s" % folder_path)
		return { "names": temp_names, "contents": temp_contents, "actives": temp_actives }

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".txt"):
			var file_path = folder_path + file_name
			var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
			if file:
				temp_names.append(file_name)
				var content = file.get_as_text()
				temp_contents.append(content)
				temp_actives.append(_to_actives(content))
				file.close()
			else:
				push_error("Error reading file: %s" % file_path)
		file_name = dir.get_next()

	dir.list_dir_end()

	return { "names": temp_names, "contents": temp_contents, "actives": temp_actives }

func _to_actives(content: String) -> Array:
	var lines = content.strip_edges().split("\n")

	if lines.size() != 4:
		push_error("Invalid number of lines: %d. Expected 4." % lines.size())
		return []

	var beats_amount: int = GameState.total_beats
	var bool_array: Array = []

	for i in range(4):
		var row: Array[bool] = []
		var line = lines[i].strip_edges()
		for j in range(beats_amount):
			row.append(line[j + 1] == "1")  # j+1 to skip the leading label character
		bool_array.append(row)

	return bool_array

func _previous_template():
	current_template -= 1
	if current_template < 0:
		current_template = names.size() - 1

func _next_template():
	current_template += 1
	if current_template >= names.size():
		current_template = 0

func _set_template():
	EventBus.template_set.emit(get_current_actives())

func _toggle_show_template():
	show_template = !show_template

func get_current_actives() -> Array:
	return actives[current_template]
