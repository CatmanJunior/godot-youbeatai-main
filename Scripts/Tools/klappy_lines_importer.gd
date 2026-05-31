@tool
extends EditorScript
## Generates the spoken-line libraries from CSV.
##
## Run from the Godot editor: open this script and choose File > Run (Ctrl+Shift+X).
##
## For each line set it (re)generates, from its CSV:
##   1. An enum of line ids  -> the enum .gd file (always includes NONE = -1)
##   2. One KlappyLineData .tres per row -> the lines dir
##   3. A KlappyLineLibrary registry .tres used at runtime
##
## Line CSV columns (header row required):
##   id,text,title,use_tts,use_bubble,show_continue,interrupt,rate
## The [code]id[/code] column is the enum member name (e.g. ACH_TRACK_2); its position in
## the file determines the enum integer value (members start at 0; NONE is -1).
##
## Two line sets are generated:
##   • Klappy reaction/feedback lines -> KlappyLine    (Data/klappy_lines.csv)
##   • Tutorial step lines            -> TutorialLine  (Data/tutorial_lines.csv)
## Tutorial steps themselves stay authored by hand in
## res://Scripts/Tutorial/tutorial_steps.tres; each step references a TutorialLine value.

const KLAPPY_CSV: String = "res://Data/klappy_lines.csv"
const KLAPPY_ENUM: String = "res://Scripts/Klappy/klappy_line.gd"
const KLAPPY_ENUM_NAME: String = "KlappyLine"
const KLAPPY_LINES_DIR: String = "res://Resources/Klappy/Lines"
const KLAPPY_REGISTRY: String = "res://Resources/Klappy/klappy_lines_registry.tres"

const TUTORIAL_CSV: String = "res://Data/tutorial_lines.csv"
const TUTORIAL_ENUM: String = "res://Scripts/Tutorial/tutorial_line.gd"
const TUTORIAL_ENUM_NAME: String = "TutorialLine"
const TUTORIAL_LINES_DIR: String = "res://Resources/Tutorial/Lines"
const TUTORIAL_REGISTRY: String = "res://Resources/Tutorial/tutorial_lines_registry.tres"


func _run() -> void:
	_import_lines(KLAPPY_CSV, KLAPPY_ENUM, KLAPPY_ENUM_NAME, KLAPPY_LINES_DIR, KLAPPY_REGISTRY)
	_import_lines(TUTORIAL_CSV, TUTORIAL_ENUM, TUTORIAL_ENUM_NAME, TUTORIAL_LINES_DIR, TUTORIAL_REGISTRY)

	var fs := EditorInterface.get_resource_filesystem()
	if fs != null:
		fs.scan()


func _import_lines(csv_path: String, enum_path: String, enum_name: String, lines_dir: String, registry_path: String) -> void:
	var rows: Array = _read_csv(csv_path)
	if rows.is_empty():
		push_error("KlappyLinesImporter: no data rows found in %s" % csv_path)
		return

	var headers: PackedStringArray = rows[0]
	var col: Dictionary = {}
	for i in headers.size():
		col[headers[i].strip_edges()] = i

	for required in ["id", "text", "title", "use_tts", "use_bubble", "show_continue", "interrupt", "rate"]:
		if not col.has(required):
			push_error("KlappyLinesImporter: missing required column '%s' in CSV header" % required)
			return

	_ensure_dir(lines_dir)

	var ids: PackedStringArray = []
	var library := KlappyLineLibrary.new()

	for row_index in range(1, rows.size()):
		var fields: PackedStringArray = rows[row_index]
		if fields.is_empty() or _row_is_blank(fields):
			continue

		var id_name: String = fields[col["id"]].strip_edges()
		if id_name.is_empty():
			push_warning("KlappyLinesImporter: skipping row %d with empty id" % row_index)
			continue

		var enum_value: int = ids.size()
		ids.append(id_name)

		var line := KlappyLineData.new()
		line.id = enum_value
		line.text = _field(fields, col, "text")
		line.title = _field(fields, col, "title")
		line.use_tts = _to_bool(_field(fields, col, "use_tts"), true)
		line.use_bubble = _to_bool(_field(fields, col, "use_bubble"), true)
		line.show_continue = _to_bool(_field(fields, col, "show_continue"), false)
		line.interrupt = _to_bool(_field(fields, col, "interrupt"), false)
		line.rate = _to_float(_field(fields, col, "rate"), 1.0)

		var line_path: String = "%s/%s.tres" % [lines_dir, id_name]
		var save_err: int = ResourceSaver.save(line, line_path)
		if save_err != OK:
			push_error("KlappyLinesImporter: failed to save %s (error %d)" % [line_path, save_err])
			return
		library.lines.append(line)

	_write_enum(ids, enum_path, enum_name)

	var reg_err: int = ResourceSaver.save(library, registry_path)
	if reg_err != OK:
		push_error("KlappyLinesImporter: failed to save registry (error %d)" % reg_err)
		return

	print("KlappyLinesImporter: generated %d lines for %s." % [ids.size(), enum_name])


# ── Helpers ───────────────────────────────────────────────────────────────────

func _read_csv(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("KlappyLinesImporter: cannot open %s" % path)
		return []
	var rows: Array = []
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line(",")
		rows.append(line)
	file.close()
	return rows


func _row_is_blank(fields: PackedStringArray) -> bool:
	for f in fields:
		if not f.strip_edges().is_empty():
			return false
	return true


func _field(fields: PackedStringArray, col: Dictionary, key: String) -> String:
	var index: int = col[key]
	if index >= fields.size():
		return ""
	return fields[index].strip_edges()


func _to_bool(value: String, default_value: bool) -> bool:
	var v: String = value.strip_edges().to_lower()
	if v.is_empty():
		return default_value
	return v == "true" or v == "1" or v == "yes"


func _to_float(value: String, default_value: float) -> float:
	var v: String = value.strip_edges()
	if v.is_valid_float():
		return v.to_float()
	return default_value


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _write_enum(ids: PackedStringArray, enum_path: String, enum_name: String) -> void:
	var lines: PackedStringArray = []
	lines.append("class_name %s" % enum_name)
	lines.append("## GENERATED FILE — do not edit by hand.")
	lines.append("## Regenerate via Scripts/Tools/klappy_lines_importer.gd (File > Run).")
	lines.append("##")
	lines.append("## Values are sourced from the 'id' column of the source CSV.")
	lines.append("## NONE (-1) means 'no line'; authored ids start at 0.")
	lines.append("")
	lines.append("enum Id {")
	lines.append("\tNONE = -1,")
	for id_name in ids:
		lines.append("\t%s," % id_name)
	lines.append("}")
	lines.append("")

	var content: String = "\n".join(lines)
	var file := FileAccess.open(enum_path, FileAccess.WRITE)
	if file == null:
		push_error("KlappyLinesImporter: cannot write enum to %s" % enum_path)
		return
	file.store_string(content)
	file.close()
