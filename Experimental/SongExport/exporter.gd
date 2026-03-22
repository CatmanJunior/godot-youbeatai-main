extends Node
class_name Exporter

enum ExportMode {NONE, BEAT, SONG, INTERACTIVE}

@export var loading: LoadingContainer
@export var rec_button: Button

var recorder: AudioEffectRecord
var is_recording: bool = false
var export_mode: ExportMode = ExportMode.NONE
var do_mail: bool = true
var _awaiting_first_beat: bool = false
var _sections_completed: int = 0
var _target_section_count: int = 0


func _ready():
	var bus = AudioServer.get_bus_index("SubMaster")
	recorder = AudioServer.get_bus_effect(bus, 4)
	EventBus.export_requested.connect(_on_export_requested)
	EventBus.beat_triggered.connect(_on_beat)
	EventBus.recording_stopped.connect(_on_recording_stopped)


func _on_export_requested(mail: bool, song: bool):
	do_mail = mail
	start_export(ExportMode.SONG if song else ExportMode.BEAT)

func _on_rec_button_pressed():
	start_export(ExportMode.INTERACTIVE)

func start_export(mode: ExportMode):
	# Interactive toggles: pressing again stops the recording.
	if is_recording:
		if mode == ExportMode.INTERACTIVE:
			_stop_recording()
		return

	is_recording = true
	export_mode = mode
	_awaiting_first_beat = true
	_sections_completed = 0

	if mode != ExportMode.INTERACTIVE:
		loading.open()

	match mode:
		ExportMode.SONG:
			_target_section_count = GameState.sections.size()
		_:
			_target_section_count = 1

	# Stop playback, wait briefly for audio to settle, then begin.
	if GameState.playing:
		EventBus.playing_change_requested.emit(false)

	await get_tree().create_timer(0.75).timeout

	var start_section: int
	match mode:
		ExportMode.SONG:
			start_section = 0
		_:
			start_section = GameState.current_section_index

	EventBus.section_switch_requested.emit(start_section)
	GameState.current_beat = GameState.total_beats - 1

	await get_tree().process_frame

	EventBus.playing_change_requested.emit(true)
	EventBus.start_recording_requested.emit()


func _on_beat(_beat: int):
	if export_mode == ExportMode.NONE or export_mode == ExportMode.INTERACTIVE:
		return

	# Skip the very first beat after recording starts (the initial beat 0).
	if _awaiting_first_beat:
		_awaiting_first_beat = false
		return

	_update_loading_progress()

	if GameState.current_beat != 0:
		return

	# Beat wrapped back to 0 — one section just finished.
	_sections_completed += 1

	if _sections_completed >= _target_section_count:
		_stop_recording()
	elif export_mode == ExportMode.SONG:
		EventBus.section_switch_requested.emit(GameState.current_section_index + 1)


func _stop_recording():
	EventBus.playing_change_requested.emit(false)
	# Brief tail to avoid cutting off the last note.
	await get_tree().create_timer(0.75).timeout
	EventBus.stop_recording_requested.emit()


func _update_loading_progress():
	var total: int = GameState.total_beats * _target_section_count
	var current: int = GameState.current_beat + (GameState.total_beats * _sections_completed)
	loading.set_progress(float(current) / total)


func _on_recording_stopped(recording: AudioStream):
	if not is_recording:
		return

	var filename = get_file_name()
	#TODO mail export
	# var path = Mailer.GetDocumentspath().path_join(filename)
	
	recording.save_to_wav(filename)

	if export_mode != ExportMode.INTERACTIVE:
		loading.close()

	export_mode = ExportMode.NONE
	is_recording = false

func get_file_name() -> String:
	var date = Time.get_date_string_from_system()
	var time = Time.get_time_string_from_system().replace(":", "-")
	var filename = "%s %s_%s.wav" % [GameState.export_name, date, time]
	return filename