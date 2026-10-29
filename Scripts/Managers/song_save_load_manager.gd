extends Node
class_name SongSaveLoadManager
## Saves and loads [SongData] as [code].ritme[/code] files at a location chosen by the player.
##
## Desktop uses the native file dialog. Web uses the browser save picker when
## available (otherwise a download) and a file input for loading.
## Press [kbd]S[/kbd] to save and [kbd]L[/kbd] to load, or emit
## [signal EventBus.save_song_requested] / [signal EventBus.load_song_requested].
##
## A [code].ritme[/code] file is a text [SongData] resource. Files are checked
## before loading because Godot resources can embed scripts.

const FILE_EXTENSION: String = "ritme"
const FILE_FILTER: String = "*.ritme ; Ritme Robot liedje"
const TEMP_DIR: String = "user://songs"
const TEMP_SAVE_PATH: String = "user://songs/_save_tmp.tres"
const TEMP_LOAD_PATH: String = "user://songs/_load_tmp.tres"
const MAX_FILE_SIZE: int = 256 * 1024 * 1024
## Only scripts from these folders may be referenced by a song file.
const ALLOWED_SCRIPT_DIRS: Array[String] = [
	"res://Scripts/DataClasses/",
	"res://Scripts/soundfont/",
	"res://Experimental/chords/",
]

const ERROR_SAVE_FAILED: String = "Opslaan is niet gelukt."
const ERROR_TOO_LARGE: String = "Dit bestand is te groot."

const JS_HELPERS: String = """
window.ritmeRobotFiles = {
	hasSavePicker: function () {
		return typeof window.showSaveFilePicker === 'function' && window.self === window.top;
	},
	save: function (b64, name, callback) {
		(async function () {
			try {
				const handle = await window.showSaveFilePicker({
					suggestedName: name,
					types: [{ description: 'Ritme Robot liedje', accept: { 'application/octet-stream': ['.ritme'] } }],
				});
				const blob = await (await fetch('data:application/octet-stream;base64,' + b64)).blob();
				const writable = await handle.createWritable();
				await writable.write(blob);
				await writable.close();
				callback(handle.name);
			} catch (e) {
				callback(e && e.name === 'AbortError' ? '' : '!' + String(e));
			}
		})();
	},
	open: function (callback) {
		const input = document.createElement('input');
		input.type = 'file';
		input.accept = '.ritme';
		input.onchange = function () {
			const file = input.files && input.files[0];
			if (!file) {
				return;
			}
			const reader = new FileReader();
			reader.onload = function () {
				const url = String(reader.result);
				callback(file.name, url.substring(url.indexOf(',') + 1), file.size);
			};
			reader.onerror = function () {
				callback(file.name, '', file.size);
			};
			reader.readAsDataURL(file);
		};
		input.click();
	},
};
"""

var _save_dialog: FileDialog
var _load_dialog: FileDialog
var _pending_save_bytes: PackedByteArray
var _pending_save_name: String = ""

## In the main menu, a loaded song is stored in [member SongState.pending_song]
## and the game scene is opened; saving and key shortcuts are disabled.
@export var main_menu_mode: bool = false

# JavaScript objects must stay referenced for the callbacks to remain valid.
var _js_files: JavaScriptObject
var _js_save_callback: JavaScriptObject
var _js_load_callback: JavaScriptObject


func _ready() -> void:
	EventBus.save_song_requested.connect(_on_save_song_requested)
	EventBus.load_song_requested.connect(_on_load_song_requested)
	if not main_menu_mode:
		EventBus.players_initialized.connect(func() -> void: _apply_pending_song.call_deferred())
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_HELPERS, true)
		_js_files = JavaScriptBridge.get_interface("ritmeRobotFiles")
		_js_save_callback = JavaScriptBridge.create_callback(_on_web_save_finished)
		_js_load_callback = JavaScriptBridge.create_callback(_on_web_file_opened)
	else:
		_save_dialog = _create_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, "Liedje opslaan")
		_save_dialog.file_selected.connect(_on_save_path_selected)
		_save_dialog.canceled.connect(func() -> void: _pending_save_bytes = PackedByteArray())
		_load_dialog = _create_file_dialog(FileDialog.FILE_MODE_OPEN_FILE, "Liedje openen")
		_load_dialog.file_selected.connect(_on_load_path_selected)


func _unhandled_key_input(event: InputEvent) -> void:
	if main_menu_mode or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		match event.keycode:
			KEY_S:
				_save_song()
			KEY_L:
				_load_song()


func _on_save_song_requested() -> void:
	if not main_menu_mode:
		_save_song()


func _on_load_song_requested() -> void:
	_load_song()


# ── Private ───────────────────────────────────────────────────────────────────

func _save_song() -> void:
	# Snapshot now so the saved song matches the moment the player pressed save.
	var bytes := _serialize_current_song()
	if bytes.is_empty():
		_fail(ERROR_SAVE_FAILED)
		return
	var file_name := "Ritme Robot liedje %s.%s" % [Time.get_date_string_from_system(), FILE_EXTENSION]

	if OS.has_feature("web"):
		if _js_files != null and bool(_js_files.call("hasSavePicker")):
			_pending_save_bytes = bytes
			_pending_save_name = file_name
			_js_files.call("save", Marshalls.raw_to_base64(bytes), file_name, _js_save_callback)
		else:
			_download(bytes, file_name)
		return

	_pending_save_bytes = bytes
	_save_dialog.current_file = file_name
	_save_dialog.popup_centered_ratio(0.6)


func _load_song() -> void:
	if OS.has_feature("web"):
		if _js_files != null:
			_js_files.call("open", _js_load_callback)
		return
	_load_dialog.popup_centered_ratio(0.6)


func _serialize_current_song() -> PackedByteArray:
	var err := DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	if err != OK:
		push_error("SongSaveLoadManager: cannot create %s (error %d)" % [TEMP_DIR, err])
		return PackedByteArray()
	if SongData.from_current().save_to_file(TEMP_SAVE_PATH) != OK:
		return PackedByteArray()
	var bytes := FileAccess.get_file_as_bytes(TEMP_SAVE_PATH)
	DirAccess.remove_absolute(TEMP_SAVE_PATH)
	return bytes


func _load_from_bytes(bytes: PackedByteArray, source_name: String) -> void:
	if bytes.size() > MAX_FILE_SIZE:
		_fail(ERROR_TOO_LARGE)
		return
	var problem := _check_song_text(bytes.get_string_from_utf8())
	if not problem.is_empty():
		push_warning("SongSaveLoadManager: rejected %s" % source_name)
		_fail(problem)
		return

	if DirAccess.make_dir_recursive_absolute(TEMP_DIR) != OK:
		_fail(SongData.ERROR_INVALID)
		return
	var file := FileAccess.open(TEMP_LOAD_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SongSaveLoadManager: cannot write %s (error %d)" % [TEMP_LOAD_PATH, FileAccess.get_open_error()])
		_fail(SongData.ERROR_INVALID)
		return
	file.store_buffer(bytes)
	file.close()
	var song := SongData.load_from_file(TEMP_LOAD_PATH)
	DirAccess.remove_absolute(TEMP_LOAD_PATH)
	if song == null:
		_fail(SongData.ERROR_INVALID)
		return

	var invalid := song.validate()
	if not invalid.is_empty():
		_fail(invalid)
		return
	song.migrate()
	print("SongSaveLoadManager: song loaded ← %s (saved with game version %s)" % [source_name, song.version])
	if not main_menu_mode:
		song.apply_to_current()
		return

	SongState.pending_song = song
	if song.soundbank:
		SoundBankLoader._patch_note_player_settings(song.soundbank)
		SongState.selected_soundbank = song.soundbank
	GameState.use_tutorial = false
	TTSHelper.init()
	SceneChanger.go_to_main()


func _apply_pending_song() -> void:
	var song: SongData = SongState.pending_song
	if song == null:
		return
	SongState.pending_song = null
	# Wait for SectionManager's initial next-frame section switch so it can't override the loaded section.
	await get_tree().process_frame
	song.apply_to_current()


## Returns an error message when the text is not a safe [SongData] file of a
## supported version, otherwise an empty string.
func _check_song_text(text: String) -> String:
	var header := text.get_slice("\n", 0)
	if not header.begins_with("[gd_resource") or not header.contains("script_class=\"SongData\""):
		return SongData.ERROR_INVALID

	var version_match := RegEx.create_from_string("(?m)^format_version = (\\d+)").search(text)
	if version_match and version_match.get_string(1).to_int() > SongData.FORMAT_VERSION:
		return SongData.ERROR_NEWER_VERSION

	# Embedded scripts or inline objects could run code while loading.
	if text.contains("Object(") or RegEx.create_from_string("(?m)^\\[sub_resource [^\\]]*type=\"[^\"]*Script\"").search(text):
		return SongData.ERROR_INVALID

	for ext: RegExMatch in RegEx.create_from_string("(?m)^\\[ext_resource ([^\\]]*)\\]").search_all(text):
		if not _is_allowed_external(ext.get_string(1)):
			return SongData.ERROR_INVALID
	return ""


func _is_allowed_external(attributes: String) -> bool:
	var path := _get_attribute(attributes, "path")
	# Godot resolves the uid before the path, so check where the uid points.
	var uid_text := _get_attribute(attributes, "uid")
	if not uid_text.is_empty():
		var uid := ResourceUID.text_to_id(uid_text)
		if ResourceUID.has_id(uid):
			path = ResourceUID.get_id_path(uid)
	if not path.begins_with("res://") or path.contains(".."):
		return false
	if _get_attribute(attributes, "type") == "Script" or path.get_extension() in ["gd", "cs"]:
		return ALLOWED_SCRIPT_DIRS.any(func(dir: String) -> bool: return path.begins_with(dir))
	return true


func _get_attribute(attributes: String, attribute_name: String) -> String:
	var found := RegEx.create_from_string("(?:^|\\s)%s=\"([^\"]*)\"" % attribute_name).search(attributes)
	return found.get_string(1) if found else ""


func _fail(message: String) -> void:
	push_warning("SongSaveLoadManager: %s" % message)
	EventBus.song_file_failed.emit(message)


# ── Desktop ──────────────────────────────────────────────────────────────────────────────

func _create_file_dialog(mode: FileDialog.FileMode, dialog_title: String) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray([FILE_FILTER])
	dialog.mode_overrides_title = false
	dialog.title = dialog_title
	var default_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Ritme Robot")
	DirAccess.make_dir_recursive_absolute(default_dir)
	dialog.current_dir = default_dir
	add_child(dialog)
	return dialog


func _on_save_path_selected(path: String) -> void:
	if path.get_extension().to_lower() != FILE_EXTENSION:
		path += "." + FILE_EXTENSION
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SongSaveLoadManager: cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		_fail(ERROR_SAVE_FAILED)
		return
	var stored := file.store_buffer(_pending_save_bytes)
	file.close()
	_pending_save_bytes = PackedByteArray()
	if not stored:
		_fail(ERROR_SAVE_FAILED)
		return
	print("SongSaveLoadManager: song saved → %s" % path)
	EventBus.saving_completed.emit(path)


func _on_load_path_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SongSaveLoadManager: cannot read %s (error %d)" % [path, FileAccess.get_open_error()])
		_fail(SongData.ERROR_INVALID)
		return
	if file.get_length() > MAX_FILE_SIZE:
		_fail(ERROR_TOO_LARGE)
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	_load_from_bytes(bytes, path)


# ── Web ─────────────────────────────────────────────────────────────────────────────────

func _download(bytes: PackedByteArray, file_name: String) -> void:
	JavaScriptBridge.download_buffer(bytes, file_name, "application/octet-stream")
	EventBus.saving_completed.emit(file_name)


## JS callback: [saved file name] on success, "" when cancelled, "!error" on failure.
func _on_web_save_finished(args: Array) -> void:
	var result := str(args[0]) if args.size() > 0 else "!"
	if result.begins_with("!"):
		# The save picker is unavailable here (e.g. blocked); fall back to a normal download.
		push_warning("SongSaveLoadManager: save picker failed (%s), downloading instead" % result.substr(1))
		_download(_pending_save_bytes, _pending_save_name)
	elif not result.is_empty():
		EventBus.saving_completed.emit(result)
	_pending_save_bytes = PackedByteArray()


## JS callback: [file name, base64 contents, file size].
func _on_web_file_opened(args: Array) -> void:
	if args.size() < 3:
		return
	var source_name := str(args[0])
	if int(args[2]) > MAX_FILE_SIZE:
		_fail(ERROR_TOO_LARGE)
		return
	var base64 := str(args[1])
	if base64.is_empty():
		_fail(SongData.ERROR_INVALID)
		return
	_load_from_bytes(Marshalls.base64_to_raw(base64), source_name)
