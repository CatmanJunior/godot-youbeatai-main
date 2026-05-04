class_name Exporter
extends Node

@export var recording := false
@export var started := false

@export var mail_when_done := false
@export var song_mode := false
var recorder: AudioEffectRecord

var data: ExportRecordingData

func _ready():
	_get_recorder()

	EventBus.beat_triggered.connect(on_beat)
	EventBus.section_switched.connect(section_switched)
	
	EventBus.export_requested.connect(start_recording)


func start_recording(mail: bool, mode_export_song: bool):
	mail_when_done = mail
	song_mode = mode_export_song

	data = _create_data_object()

	EventBus.playing_change_requested.emit(false)

	# wait 1 frame to resolve play state
	await get_tree().process_frame

	EventBus.beat_seek_requested.emit(0)
	if song_mode:
		GameState.song_mode = true
		EventBus.on_song_mode_changed.emit()
		EventBus.section_switch_requested.emit(0)

	# wait 1 frame to resolve ring state
	await get_tree().process_frame
	# start 
	recorder.set_recording_active(true)
	## 0.1 seconds of silence at the start of the recording
	await get_tree().create_timer(0.1).timeout

	EventBus.playing_change_requested.emit(true)
	recording = true

func stop_recording():
	recording = false
	## 0.1 seconds of silence at the end of the recording
	await get_tree().create_timer(0.1).timeout
	recorder.set_recording_active(false)
	data.audio_stream = recorder.get_recording()
	EventBus.export_recording_requested.emit(data)

func on_beat(beat: int):
	if not recording:
		return

	data.actual_recording_length += GameState.beat_duration
	EventBus.export_progress_update.emit( data.actual_recording_length / data.max_recording_length)

	if song_mode: 
		return

	# single beat export check
	if beat == 0:
		recording = false
		# stop playing
		EventBus.playing_change_requested.emit(false)
		stop_recording()

func section_switched(section: SectionData):
	if not recording or not song_mode:
		return

	if section.index == 0:
		started = false
		recording = false
		# stop playing
		EventBus.playing_change_requested.emit(false)
		stop_recording()

func _get_recorder():
	var sub_master = AudioServer.get_bus_index("SubMaster")
	var count = AudioServer.get_bus_effect_count(sub_master)
	# recorder should be the last effect
	recorder = AudioServer.get_bus_effect(sub_master, count - 1) 

func _create_data_object() -> ExportRecordingData:
	var result = ExportRecordingData.new()
	result.email = mail_when_done
	result.song_mode = song_mode
	result.download = !mail_when_done
	result.email_address = GameState.export_mail
	result.name = GameState.export_name

	if not song_mode:
		result.section_index = SongState.current_section_index

	result.state = RecordingData.State.RECORDING
	if song_mode:
		result.max_recording_length = GameState.beat_duration * SongState.total_beats * SongState.section_count()
	else:
		result.max_recording_length = SongState.total_beats * GameState.beat_duration

	result.actual_recording_length = 0
	return result
