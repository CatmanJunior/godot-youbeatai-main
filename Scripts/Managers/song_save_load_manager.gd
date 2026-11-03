extends Node
class_name SongSaveLoadManager
## Saves and loads [SongData] as [code].ritme[/code] files at a location chosen by the player.
##
## Desktop uses a native file dialog. Android web uses a browser-local song
## library; other web browsers use the browser's file picker or downloads.
## Press [kbd].[/kbd] to save and [kbd],[/kbd] to load, or emit
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
const LOADING_OVERLAY_SCENE: PackedScene = preload("res://Scenes/UI_Components/song_loading_overlay.tscn")
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
	isAndroid: function () {
		return /Android/i.test(navigator.userAgent) ||
			!!(navigator.userAgentData && navigator.userAgentData.platform === 'Android');
	},
	localDatabase: function () {
		return new Promise(function (resolve, reject) {
			const request = indexedDB.open('ritme-robot-songs', 1);
			request.onupgradeneeded = function () {
				request.result.createObjectStore('songs');
			};
			request.onsuccess = function () { resolve(request.result); };
			request.onerror = function () { reject(request.error); };
			request.onblocked = function () { reject(new Error('Storage is blocked')); };
		});
	},
	listLocal: function (callback) {
		window.ritmeRobotFiles.localDatabase().then(function (db) {
			const tx = db.transaction('songs', 'readonly');
			const request = tx.objectStore('songs').getAllKeys();
			tx.oncomplete = function () { db.close(); callback('ok', JSON.stringify(request.result)); };
			tx.onabort = function () { db.close(); callback('error', ''); };
		}).catch(function () { callback('error', ''); });
	},
	saveLocal: function (name, b64, overwrite, callback) {
		window.ritmeRobotFiles.localDatabase().then(function (db) {
			const tx = db.transaction('songs', 'readwrite');
			const store = tx.objectStore('songs');
			const request = overwrite ? store.put(b64, name) : store.add(b64, name);
			tx.oncomplete = function () { db.close(); callback('ok'); };
			tx.onabort = function () {
				const duplicate = request.error && request.error.name === 'ConstraintError';
				db.close(); callback(duplicate ? 'exists' : 'error');
			};
		}).catch(function () { callback('error'); });
	},
	loadLocal: function (name, callback) {
		window.ritmeRobotFiles.localDatabase().then(function (db) {
			const tx = db.transaction('songs', 'readonly');
			const request = tx.objectStore('songs').get(name);
			tx.oncomplete = function () {
				const value = request.result;
				db.close();
				callback(typeof value === 'string' ? 'ok' : 'missing', name, value || '');
			};
			tx.onabort = function () { db.close(); callback('error', name, ''); };
		}).catch(function () { callback('error', name, ''); });
	},
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
## Root-owned so it stays visible while the main-menu scene is replaced.
static var _loading_overlay: CanvasLayer

## In the main menu, a loaded song is stored in [member SongState.pending_song]
## and the game scene is opened; saving and key shortcuts are disabled.
@export var main_menu_mode: bool = false

# JavaScript objects must stay referenced for the callbacks to remain valid.
var _js_files: JavaScriptObject
var _js_save_callback: JavaScriptObject
var _js_load_callback: JavaScriptObject
var _js_local_list_callback: JavaScriptObject
var _js_local_save_callback: JavaScriptObject
var _js_local_load_callback: JavaScriptObject
var _use_local_library: bool = false
var _local_dialog: ConfirmationDialog
var _local_overwrite_dialog: ConfirmationDialog
var _local_name: LineEdit
var _local_name_label: Label
var _local_list: ItemList
var _local_status: Label
var _local_names: Array[String] = []
var _local_saving: bool = false
var _local_busy: bool = false
var _local_available: bool = false
var _local_pending_name: String = ""


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
		_use_local_library = _js_files != null and bool(_js_files.call("isAndroid"))
		if _use_local_library:
			_js_local_list_callback = JavaScriptBridge.create_callback(_on_local_listed)
			_js_local_save_callback = JavaScriptBridge.create_callback(_on_local_saved)
			_js_local_load_callback = JavaScriptBridge.create_callback(_on_local_loaded)
			_create_local_library_dialog()
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
			KEY_PERIOD:
				_save_song()
			KEY_COMMA:
				_load_song()


func _on_save_song_requested() -> void:
	if not main_menu_mode:
		_save_song()


func _on_load_song_requested() -> void:
	_load_song()


# ── Private ───────────────────────────────────────────────────────────────────

func _save_song() -> void:
	if is_instance_valid(_loading_overlay) or _local_busy or (is_instance_valid(_local_dialog) and _local_dialog.visible):
		return
	# Snapshot now so the saved song matches the moment the player pressed save.
	var bytes := _serialize_current_song()
	if bytes.is_empty():
		_fail(ERROR_SAVE_FAILED)
		return
	var file_name := "Ritme Robot liedje %s.%s" % [Time.get_date_string_from_system(), FILE_EXTENSION]

	if OS.has_feature("web"):
		if _use_local_library:
			if bytes.size() > MAX_FILE_SIZE:
				_fail(ERROR_TOO_LARGE)
				return
			_pending_save_bytes = bytes
			_open_local_library(true)
			return
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
	if is_instance_valid(_loading_overlay) or _local_busy or (is_instance_valid(_local_dialog) and _local_dialog.visible):
		return
	if OS.has_feature("web"):
		if _use_local_library:
			_open_local_library(false)
			return
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
	if not await _begin_loading():
		return
	await _restore_from_bytes(bytes, source_name)


func _begin_loading() -> bool:
	if is_instance_valid(_loading_overlay):
		push_warning("SongSaveLoadManager: a song is already loading.")
		return false
	_loading_overlay = LOADING_OVERLAY_SCENE.instantiate() as CanvasLayer
	get_tree().root.add_child(_loading_overlay)
	# Allow a rendered frame before blocking work such as file reads and deserialization.
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _finish_loading() -> void:
	# Keep the overlay through deferred UI updates and the first complete game frame.
	await get_tree().process_frame
	await get_tree().process_frame
	_clear_loading_overlay()


func _clear_loading_overlay() -> void:
	if is_instance_valid(_loading_overlay):
		_loading_overlay.get_parent().remove_child(_loading_overlay)
		_loading_overlay.queue_free()
		_loading_overlay = null


func _restore_from_bytes(bytes: PackedByteArray, source_name: String) -> void:
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
		await _finish_loading()
		return

	SongState.pending_song = song
	if song.soundbank:
		SoundBankLoader._patch_note_player_settings(song.soundbank)
		SongState.selected_soundbank = song.soundbank
	GameState.use_tutorial = false
	TTSHelper.init()
	var error: Error = get_tree().change_scene_to_file(SceneChanger.SCENE_MAIN)
	if error != OK:
		push_error("SongSaveLoadManager: cannot open game scene (error %d)." % error)
		SongState.pending_song = null
		_fail(SongData.ERROR_INVALID)


func _apply_pending_song() -> void:
	var song: SongData = SongState.pending_song
	if song == null:
		return
	SongState.pending_song = null
	# Wait for SectionManager's initial next-frame section switch so it can't override the loaded section.
	await get_tree().process_frame
	song.apply_to_current()
	await _finish_loading()


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
	_clear_loading_overlay()
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
	if not await _begin_loading():
		return
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
	await _restore_from_bytes(bytes, path)


# ── Android web song library ───────────────────────────────────────────────────

func _create_local_library_dialog() -> void:
	_local_dialog = ConfirmationDialog.new()
	_local_dialog.dialog_hide_on_ok = false
	_local_dialog.cancel_button_text = "Annuleren"
	_local_dialog.confirmed.connect(_on_local_confirmed)
	_local_dialog.canceled.connect(_on_local_canceled)
	add_child(_local_dialog)
	_local_dialog.get_ok_button().add_theme_font_size_override("font_size", 24)
	_local_dialog.get_cancel_button().add_theme_font_size_override("font_size", 24)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 350)
	content.add_theme_constant_override("separation", 8)
	_local_dialog.add_child(content)

	var explanation := Label.new()
	explanation.custom_minimum_size.x = 600
	explanation.size.x = 600
	explanation.text = "Je liedjes staan in deze browser op dit apparaat. Als je browsergegevens wist, verdwijnen ze."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 22)
	content.add_child(explanation)

	_local_name_label = Label.new()
	_local_name_label.text = "Naam van je liedje"
	_local_name_label.add_theme_font_size_override("font_size", 22)
	content.add_child(_local_name_label)
	_local_name = LineEdit.new()
	_local_name.max_length = 80
	_local_name.add_theme_font_size_override("font_size", 24)
	_local_name.text_changed.connect(func(_value: String) -> void: _update_local_controls())
	content.add_child(_local_name)

	_local_list = ItemList.new()
	_local_list.custom_minimum_size = Vector2(0, 180)
	_local_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_local_list.add_theme_font_size_override("font_size", 24)
	_local_list.add_theme_constant_override("v_separation", 12)
	_local_list.item_selected.connect(_on_local_item_selected)
	content.add_child(_local_list)

	_local_status = Label.new()
	_local_status.custom_minimum_size.x = 600
	_local_status.size.x = 600
	_local_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_local_status.add_theme_font_size_override("font_size", 22)
	content.add_child(_local_status)

	_local_overwrite_dialog = ConfirmationDialog.new()
	_local_overwrite_dialog.title = "Liedje vervangen?"
	_local_overwrite_dialog.ok_button_text = "Vervangen"
	_local_overwrite_dialog.cancel_button_text = "Annuleren"
	_local_overwrite_dialog.confirmed.connect(func() -> void: _save_local_song(true))
	_local_dialog.add_child(_local_overwrite_dialog)
	_local_overwrite_dialog.get_label().add_theme_font_size_override("font_size", 22)
	_local_overwrite_dialog.get_ok_button().add_theme_font_size_override("font_size", 24)
	_local_overwrite_dialog.get_cancel_button().add_theme_font_size_override("font_size", 24)


func _open_local_library(saving: bool) -> void:
	_local_saving = saving
	_local_available = false
	_local_pending_name = ""
	_local_names.clear()
	_local_list.clear()
	_local_name.visible = saving
	_local_name_label.visible = saving
	_local_name.text = "Liedje " + Time.get_datetime_string_from_system().replace("T", " ")
	_local_dialog.title = "Liedje opslaan" if saving else "Liedje openen"
	_local_dialog.ok_button_text = "Opslaan" if saving else "Openen"
	_local_status.text = "Liedjes laden..."
	_local_busy = true
	_update_local_controls()
	_local_dialog.popup_centered(Vector2i(720, 500))
	_js_files.call("listLocal", _js_local_list_callback)


func _update_local_controls() -> void:
	if not is_instance_valid(_local_dialog):
		return
	var can_confirm: bool = not _local_name.text.strip_edges().is_empty() if _local_saving else not _local_list.get_selected_items().is_empty()
	_local_dialog.get_ok_button().disabled = _local_busy or not _local_available or not can_confirm
	_local_dialog.get_cancel_button().disabled = _local_busy
	_local_name.editable = not _local_busy
	_local_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if _local_busy else Control.MOUSE_FILTER_STOP


func _on_local_listed(args: Array) -> void:
	_local_busy = false
	_local_available = false
	if not _local_dialog.visible:
		_pending_save_bytes = PackedByteArray()
		return
	if args.size() < 2 or str(args[0]) != "ok":
		_local_status.text = "Je liedjes kunnen niet worden geladen. Controleer of opslag in je browser is toegestaan."
		_update_local_controls()
		return
	var names: Variant = JSON.parse_string(str(args[1]))
	if not names is Array:
		_local_status.text = "Je liedjes kunnen niet worden geladen."
		_update_local_controls()
		return
	_local_available = true
	for entry: Variant in names:
		if entry is String:
			_local_names.append(entry)
			_local_list.add_item(entry)
	if _local_names.is_empty():
		_local_status.text = "Nog geen liedjes opgeslagen."
	elif _local_saving:
		_local_status.text = "Typ een naam of kies een liedje om te vervangen."
	else:
		_local_status.text = "Kies een liedje uit de lijst."
	_update_local_controls()


func _on_local_item_selected(index: int) -> void:
	if _local_saving and index >= 0 and index < _local_names.size():
		_local_name.text = _local_names[index]
	_update_local_controls()


func _on_local_confirmed() -> void:
	if _local_busy:
		return
	if _local_saving:
		_local_pending_name = _local_name.text.strip_edges()
		if _local_pending_name.is_empty() or "/" in _local_pending_name or "\\" in _local_pending_name:
			_local_status.text = "Kies een naam zonder / of \\."
			return
		if _local_pending_name in _local_names:
			_confirm_local_overwrite()
		else:
			_save_local_song(false)
	else:
		var selected: PackedInt32Array = _local_list.get_selected_items()
		if selected.is_empty():
			return
		_local_busy = true
		_local_status.text = "Liedje openen..."
		_update_local_controls()
		_js_files.call("loadLocal", _local_names[selected[0]], _js_local_load_callback)


func _confirm_local_overwrite() -> void:
	_local_overwrite_dialog.dialog_text = "Wil je '%s' vervangen?" % _local_pending_name
	_local_overwrite_dialog.popup_centered()


func _save_local_song(overwrite: bool) -> void:
	_local_busy = true
	_local_status.text = "Liedje opslaan..."
	_update_local_controls()
	_js_files.call("saveLocal", _local_pending_name, Marshalls.raw_to_base64(_pending_save_bytes), overwrite, _js_local_save_callback)


func _on_local_saved(args: Array) -> void:
	_local_busy = false
	var result: String = str(args[0]) if not args.is_empty() else "error"
	if result == "ok":
		_local_dialog.hide()
		_pending_save_bytes = PackedByteArray()
		EventBus.saving_completed.emit(_local_pending_name)
	elif not _local_dialog.visible:
		_pending_save_bytes = PackedByteArray()
		_fail(ERROR_SAVE_FAILED)
	elif result == "exists":
		_local_status.text = "Er bestaat al een liedje met deze naam."
		_update_local_controls()
		_confirm_local_overwrite()
	else:
		_local_status.text = "Opslaan is niet gelukt. Controleer de opslagruimte en browserinstellingen."
		_update_local_controls()


func _on_local_loaded(args: Array) -> void:
	_local_busy = false
	if not _local_dialog.visible:
		return
	if args.size() < 3 or str(args[0]) != "ok":
		_local_status.text = "Dit liedje kon niet worden geopend. Probeer het opnieuw."
		_update_local_controls()
		return
	var base64: String = str(args[2])
	if base64.length() > int(ceil(float(MAX_FILE_SIZE) / 3.0)) * 4:
		_local_status.text = ERROR_TOO_LARGE
		_update_local_controls()
		return
	_local_dialog.hide()
	await _load_from_bytes(Marshalls.base64_to_raw(base64), str(args[1]))


func _on_local_canceled() -> void:
	if not _local_busy:
		_pending_save_bytes = PackedByteArray()


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
	if not await _begin_loading():
		return
	var source_name := str(args[0])
	if int(args[2]) > MAX_FILE_SIZE:
		_fail(ERROR_TOO_LARGE)
		return
	var base64 := str(args[1])
	if base64.is_empty():
		_fail(SongData.ERROR_INVALID)
		return
	await _restore_from_bytes(Marshalls.base64_to_raw(base64), source_name)
