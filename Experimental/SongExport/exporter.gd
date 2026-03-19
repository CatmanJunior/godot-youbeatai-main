extends Node
class_name Exporter

signal onExportSong(audio: AudioStreamWAV)
signal onExportBeat(audio: AudioStreamWAV)

@export var loading: LoadingContainer

@export var manager: Manager
@export var bpm_manager: BpmManager
@export var loop_button: CheckButton

@export var rec_button: Button

@export var settings_panel: Control
@export var mail_panel: Control
@export var mail_button: Button
@export var mail_field: LineEdit
@export var name_field: LineEdit

var recorder: AudioEffectRecord
var is_recording: bool = false
var cancelled = false
var path: String
var song_mode: bool = false
var export_mode: bool = false
var do_mail: bool = true

func _ready():
	var bus = AudioServer.get_bus_index("SubMaster");
	recorder = AudioServer.get_bus_effect(bus, 4);

	bpm_manager.OnBeatEvent.connect( on_beat )

func _exit_tree():
	bpm_manager.OnBeatEvent.disconnect( on_beat )

func on_beat():
	if not export_mode:
		return

	var layerCount = manager.layersAmount 
	var layerIndex = manager.currentLayerIndex
	if song_mode == false:
		layerIndex = 0
		layerCount = 1
	
	var current_beat = bpm_manager.currentBeat + ( bpm_manager.amount_of_beats * layerIndex);
	var total_beats = (bpm_manager.amount_of_beats * layerCount) - 1
	loading.set_progress( float(current_beat) / total_beats )

	if song_mode and bpm_manager.currentBeat == bpm_manager.amount_of_beats -1:
		manager.NextLayer()

func clean_up_signals():
	if mail_button.pressed.is_connected(start_beat_export):
		mail_button.pressed.disconnect(start_beat_export)
	
	if mail_button.pressed.is_connected(start_song_export):
		mail_button.pressed.disconnect(start_song_export)

func close_export_dialog():
	manager.emailPromptOpen = false
	mail_panel.visible = false
	mail_panel.position = Vector2(-636, -2000);

	clean_up_signals()

func on_mail_toggle_changed(value: bool):
	do_mail = value

func setup_beat_export_dialog():
	manager.emailPromptOpen = true
	settings_panel.visible = false
	mail_panel.visible = true
	mail_panel.position = Vector2(-636, -356);
	mail_button.pressed.connect(start_beat_export)

func setup_song_export_dialog():
	manager.emailPromptOpen = true
	settings_panel.visible = false
	mail_panel.visible = true
	mail_panel.position = Vector2(-636, -356);
	mail_button.pressed.connect(start_song_export)

func validate_form() -> bool:
	if name_field.text == "":
		return false

	if mail_field.text == "" and do_mail:
		return false

	return true

func start_beat_export():
	if is_recording:
		return;

	var beat_time = 60.0 / bpm_manager.bpm / 4.0
	var beat_length = beat_time * (bpm_manager.amount_of_beats)

	if not validate_form():
		name_field.modulate = Color.RED
		mail_field.modulate = Color.RED
		return

	await export_to_wav( beat_length, false )
	close_export_dialog()
	if do_mail:
		Mailer.SendWav(path, mail_field.text )

func start_song_export():
	if is_recording:
		return;

	var beat_time = 60.0 / bpm_manager.bpm / 4.0
	var song_length = (manager.layersAmount * beat_time * bpm_manager.amount_of_beats)
	
	if not validate_form():
		name_field.modulate = Color.RED
		mail_field.modulate = Color.RED
		return

	await export_to_wav(song_length, true)
	close_export_dialog()
	if do_mail:
		Mailer.SendWav(path, mail_field.text )

func export_to_wav(length: float, song: bool):
	is_recording = true
	loading.open()

	song_mode = song
	export_mode = true

	var cached_loop = loop_button.button_pressed
	loop_button.set_pressed_no_signal(false)

	await get_tree().process_frame
	
	if bpm_manager.playing:
		manager.OnPlayPauseButton()

	await get_tree().create_timer(0.75).timeout
	manager.SwitchLayer(0, true)
	bpm_manager.currentBeat = bpm_manager.amount_of_beats -1 
	manager.OnPlayPauseButton()
	recorder.set_recording_active(true);
	
	await get_tree().create_timer(length).timeout
	manager.OnPlayPauseButton()
	# include a small wait time to include the last note/sampling in the recording without cutting off the audio
	await get_tree().create_timer(0.75).timeout

	recorder.set_recording_active(false);
	
	var recording = recorder.get_recording()

	if song_mode:
		onExportSong.emit(recording)
	else:
		onExportBeat.emit(recording)

	var date = Time.get_date_string_from_system()
	var time = Time.get_time_string_from_system().replace(":", "-")
	var formatted_file = "\\%s %s_%s.wav" % [
		name_field.text, date, time]

	path = Mailer.GetDocumentspath() + formatted_file
	match OS.get_name():
		"windows":	
			recording.save_to_wav(path);
		
	loading.close()

	export_mode = false
	loop_button.button_pressed = cached_loop
	is_recording = false


func export_interactive():
	print("try to start a recording");
	if is_recording:
		return

	is_recording = true
	# export_mode = true
	song_mode = false

	if bpm_manager.playing:
		manager.OnPlayPauseButton()

	await get_tree().create_timer(0.75).timeout
	bpm_manager.currentBeat = bpm_manager.amount_of_beats -1 

	await get_tree().process_frame

	manager.OnPlayPauseButton()
	recorder.set_recording_active(true);

	await rec_button.pressed

	manager.OnPlayPauseButton()
	# include a small wait time to include the last note/sampling in the recording without cutting off the audio
	await get_tree().create_timer(0.75).timeout

	recorder.set_recording_active(false);
	
	var recording = recorder.get_recording()

	if song_mode:
		onExportSong.emit(recording)
	else:
		onExportBeat.emit(recording)


	is_recording = false
	# export_mode = false