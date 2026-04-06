extends Node

# UI References
var progress_bar: ProgressBar
var record_song_button: Button
var record_song_sprite: Sprite2D
var sneller_button: Button
var langzamer_button: Button

# Recording state
var voice_over: AudioStreamWAV = null
var audio_player: AudioStreamPlayer2D
var audio_effect_record: AudioEffectRecord
var should_record: bool = false
var recording: bool = false
var recording_timer: float = 0.0
var recording_length: float = 0.0
var finished: bool = false

# References
var layer_manager: Node

func _ready():
	layer_manager = %LayerManager
	
	# Setup record button
	if record_song_button:
		record_song_button.pressed.connect(_on_record_button_pressed)
	
	# Create audio player
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = "SongVoice"
	
	# Setup recording effect
	var microphone_bus_index = AudioServer.get_bus_index("Microphone")
	if microphone_bus_index >= 0:
		audio_effect_record = AudioServer.get_bus_effect(microphone_bus_index, 1)

func _process(delta: float):
	# Track button state
	if record_song_button and record_song_button.get_parent() is Node:
		var parent = record_song_button.get_parent()
		if parent.has_method("set_pressed"):
			parent.set_pressed(should_record)
	
	# Update recording timer
	if recording:
		recording_timer += delta
	else:
		recording_timer = 0.0
	
	# Update progress bar
	if recording and progress_bar and layer_manager:
		var layers_amount = layer_manager.sections_amount if layer_manager.has("sections_amount") else 4
		var total_time = layers_amount * SongState.total_beats * GameState.beat_duration
		progress_bar.value = recording_timer / total_time if total_time > 0 else 0.0
	
	# Set audio volume
	if audio_player:
		audio_player.volume_linear = 6.0

func _on_record_button_pressed():
	should_record = not should_record
	
	EventBus.buttons_disabled_requested.emit(true)
	
	# Start from last layer
	if layer_manager:
		var last_layer = layer_manager.sections_amount - 1
		EventBus.section_switch_requested.emit(last_layer)
	
	# Set beat position
	EventBus.beat_seek_requested.emit(SongState.total_beats / 2)
	EventBus.playing_change_requested.emit(true)
	EventBus.countdown_show_requested.emit()

func on_top():
	if recording:
		stop_recording()
		if voice_over:
			audio_player.play()
	else:
		if should_record:
			start_recording()
		elif voice_over:
			audio_player.play()

func start_recording():
	recording = true
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)
	
	EventBus.buttons_disabled_requested.emit(true)
	
	# Reduce volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), linear_to_db(0.1))
	
	EventBus.countdown_close_requested.emit()
	
	EventBus.recording_started.emit()


func stop_recording():
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
	
	recording_length = recording_timer
	recording = false
	should_record = false
	voice_over = audio_effect_record.get_recording() if audio_effect_record else null
	
	if voice_over:
		audio_player.stream = voice_over
	
	EventBus.buttons_disabled_requested.emit(false)
	
	# Restore volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), 0.0)
	
	finished = true
	
	EventBus.recording_stopped.emit(voice_over)
