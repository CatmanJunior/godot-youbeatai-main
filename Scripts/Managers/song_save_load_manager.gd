extends Node
class_name SongSaveLoadManager
## Handles saving and loading of [SongData] via keyboard shortcuts and EventBus signals.
##
## Press [kbd]S[/kbd] to save the current song to [code]user://songs/last_save.tres[/code].
## Press [kbd]L[/kbd] to load the last saved song from the same path.
## Both actions are also triggerable via [signal EventBus.save_song_requested] and
## [signal EventBus.load_song_requested].

const SAVE_PATH: String = "user://songs/last_save.tres"


func _ready() -> void:
	EventBus.save_song_requested.connect(_on_save_song_requested)
	EventBus.load_song_requested.connect(_on_load_song_requested)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		match event.keycode:
			KEY_S:
				_save_song()
			KEY_L:
				_load_song()


func _on_save_song_requested() -> void:
	_save_song()


func _on_load_song_requested() -> void:
	_load_song()


# ── Private ───────────────────────────────────────────────────────────────────

func _save_song() -> void:
	_ensure_save_dir()
	# Create a deep-copy snapshot of the current live SongState for serialisation.
	var song := SongData.from_current()
	var err := song.save_to_file(SAVE_PATH)
	if err == OK:
		print("SongSaveLoadManager: song saved → %s" % SAVE_PATH)
		EventBus.saving_completed.emit(SAVE_PATH)
	else:
		push_error("SongSaveLoadManager: failed to save song (error %d)" % err)


func _load_song() -> void:
	var song := SongData.load_from_file(SAVE_PATH)
	if song == null:
		push_warning("SongSaveLoadManager: no save file found at %s" % SAVE_PATH)
		return
	# Push the loaded resource into SongState and emit update signals.
	song.apply_to_current()
	print("SongSaveLoadManager: song loaded ← %s" % SAVE_PATH)


func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SongSaveLoadManager: cannot open user:// directory (error %d)" % DirAccess.get_open_error())
		return
	if not dir.dir_exists("songs"):
		var err := dir.make_dir("songs")
		if err != OK:
			push_error("SongSaveLoadManager: failed to create user://songs/ directory (error %d)" % err)
