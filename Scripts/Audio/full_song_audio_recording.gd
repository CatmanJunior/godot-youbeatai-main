extends Node

# Recording result
var recording_result: AudioStreamWAV = null
var audio_effect_record: AudioEffectRecord

# Recording state
var should_record: bool = false
var recording: bool = false
var recording_timer: float = 0.0

# Other
var recording_length: float = 0.0
var finished: bool = false

# UI references
@export var progress_bar: ProgressBar
@export var record_song_button: Button
@export var record_song_sprite: Sprite2D

# Manager references
var song_voice_over: Node
var layer_manager: Node

func _ready():
	song_voice_over = %SongVoiceOver
	layer_manager = %LayerManager

	if record_song_button:
		record_song_button.pressed.connect(_on_button)

	# Setup record effect
	var master_audio_bus = AudioServer.get_bus_index("SubMaster")
	if master_audio_bus >= 0:
		audio_effect_record = AudioServer.get_bus_effect(master_audio_bus, 0)

func _process(delta: float):
	# Set color of fake button
	if record_song_button and record_song_button.get_parent() is Node:
		var parent = record_song_button.get_parent()
		if "pressed" in parent:
			parent.pressed = should_record

	# Update recording timer
	if recording:
		recording_timer += delta
	else:
		recording_timer = 0.0

	# Set progress bar value
	if recording and progress_bar and layer_manager:
		var layers_amount = layer_manager.sections_amount
		var total_time = layers_amount * GameState.total_beats * GameState.beat_duration
		if total_time > 0:
			progress_bar.value = recording_timer / total_time

func start_recording_master():
	recording = true
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)

	if song_voice_over:
		song_voice_over.should_record = true

	EventBus.buttons_disabled_requested.emit(true)
	EventBus.countdown_close_requested.emit()

func on_top():
	if recording:
		stop_recording_master()
	elif should_record:
		start_recording_master()

func _on_button():
	if not recording and not should_record:
		should_record = true
		EventBus.buttons_disabled_requested.emit(true)

		# Start from last layer
		if layer_manager:
			var last_layer = layer_manager.sections_amount - 1
			layer_manager.switch_layer(last_layer)

		EventBus.beat_seek_requested.emit(GameState.total_beats / 2)
		EventBus.playing_change_requested.emit(true)
		EventBus.countdown_show_requested.emit()

	elif not recording and should_record:
		# Cancel should-record
		should_record = false
		EventBus.buttons_disabled_requested.emit(false)
		EventBus.countdown_close_requested.emit()

func stop_recording_master():
	recording = false
	should_record = false
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		recording_result = audio_effect_record.get_recording()

	recording_length = recording_timer
	finished = true

	EventBus.buttons_disabled_requested.emit(false)
