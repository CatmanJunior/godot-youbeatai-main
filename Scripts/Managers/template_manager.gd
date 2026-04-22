extends Node
class_name TemplateManager

static var template_names: Array[String] = []
var contents: Array[String] = []
var actives: Array = []  # Array of Array[bool] (row per sample track)

var current_template: int = 4
var show_template: bool = false

func _ready():
	EventBus.template_set_requested.connect(_set_template)
	read_templates()

func read_templates() -> Array[String]:
	var result = _load_text_files_in_directory("Resources/Templates")
	template_names = result.template_names
	contents = result.contents
	actives = result.actives
	return template_names

func _load_text_files_in_directory(folder: String) -> Dictionary:
	var folder_path = "res://%s/" % folder
	var dir = DirAccess.open(folder_path)

	var temp_names: Array[String] = []
	var temp_contents: Array[String] = []
	var temp_actives: Array = []

	if dir == null:
		push_error("Could not open directory: %s" % folder_path)
		return { "template_names": temp_names, "contents": temp_contents, "actives": temp_actives }

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".txt"):
			var file_path = folder_path + file_name
			var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
			if file:
				var template_name = file_name.left(file_name.length() - 4) # Strip ".txt"
				temp_names.append(template_name)
				var content = file.get_as_text()
				temp_contents.append(content)
				temp_actives.append(_to_actives(content))
				file.close()
			else:
				push_error("Error reading file: %s" % file_path)
		file_name = dir.get_next()

	dir.list_dir_end()

	return { "template_names": temp_names, "contents": temp_contents, "actives": temp_actives }

func _to_actives(content: String) -> Array:
	var lines = content.strip_edges().split("\n")

	if lines.size() != 4:
		push_error("Invalid number of lines: %d. Expected 4." % lines.size())
		return []

	var beats_amount: int = SongState.total_beats
	var bool_array: Array = []

	for i in range(4):
		var row: Array[bool] = []
		var line = lines[i].strip_edges()
		for j in range(beats_amount):
			row.append(line[j + 1] == "1")  # j+1 to skip the leading label character
		bool_array.append(row)

	return bool_array

func _set_template(template_index: int):
	current_template = template_index
	EventBus.template_set.emit(actives[current_template])

func _toggle_show_template():
	show_template = !show_template
