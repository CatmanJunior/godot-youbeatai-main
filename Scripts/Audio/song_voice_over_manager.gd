extends Node

# Signals for recording state
signal started_recording
signal stopped_recording

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
var game_manager: Node
var bpm_manager: Node
var layer_manager: Node
var layer_voice_over_0: Node
var layer_voice_over_1: Node
var uiManager: Node

func _ready():
	game_manager = %GameManager
	bpm_manager = %BpmManager
	layer_manager = %LayerManager
	layer_voice_over_0 = %LayerVoiceOver0
	layer_voice_over_1 = %LayerVoiceOver1
	uiManager = %UiManager
	
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
	if recording and progress_bar and game_manager and layer_manager:
		var layers_amount = layer_manager.layers_amount if layer_manager.has("layers_amount") else 4
		var beats_amount = bpm_manager.beats_amount if bpm_manager and bpm_manager.has("beats_amount") else 16
		var base_time_per_beat = bpm_manager.base_time_per_beat if bpm_manager and bpm_manager.has("base_time_per_beat") else 0.5
		
		var total_time = layers_amount * beats_amount * base_time_per_beat
		progress_bar.value = recording_timer / total_time if total_time > 0 else 0.0
	
	# Set audio volume
	if audio_player:
		audio_player.volume_linear = 6.0

func _on_record_button_pressed():
	"""Handle record button press"""
	# Enable layer loop mode
	if game_manager and game_manager.has("layer_loop_toggle"):
		game_manager.layer_loop_toggle.button_pressed = true
	
	should_record = not should_record
	
	# Disable other buttons
	if sneller_button:
		sneller_button.disabled = true
	if langzamer_button:
		langzamer_button.disabled = true
	if game_manager:
		game_manager.set_layer_switch_buttons_enabled(false)
		game_manager.play_pause_button.disabled = true
		record_song_button.disabled = true
	
	# Enable metronome
	if game_manager and game_manager.has("metronome_toggle"):
		game_manager.metronome_toggle.button_pressed = true
	
	# Start from last layer
	if layer_manager and game_manager:
		var last_layer = layer_manager.layers_amount - 1
		game_manager.switch_layer(last_layer)
	
	# Set beat position
	if bpm_manager:
		bpm_manager.current_beat = bpm_manager.beats_amount / 2
		bpm_manager.playing = true
	
	# Play metronome sound
	if game_manager and game_manager.has_method("play_extra_sfx"):
		game_manager.play_extra_sfx(game_manager.metronome_sfx)
	
	# Show countdown
	if game_manager and game_manager.has_method("show_count_down"):
		game_manager.show_count_down()

func on_top():
	"""Called when this comes to the top in the loop"""
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
	"""Start recording"""
	recording = true
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)
	
	print("recording started")
	
	# Disable layer recording buttons
	if layer_voice_over_0:
		layer_voice_over_0.record_layer_button.disabled = true
	if layer_voice_over_1:
		layer_voice_over_1.record_layer_button.disabled = true
	
	# Reduce volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), linear_to_db(0.1))
	
	# Disable metronome
	if game_manager and game_manager.has("metronome_toggle"):
		game_manager.metronome_toggle.button_pressed = false
	
	# Close countdown
	if game_manager and game_manager.has_method("close_count_down"):
		game_manager.close_count_down()
	
	started_recording.emit()

func stop_recording():
	"""Stop recording"""
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
	
	print("recording stopped")
	recording_length = recording_timer
	recording = false
	should_record = false
	voice_over = audio_effect_record.get_recording() if audio_effect_record else null
	
	if voice_over:
		audio_player.stream = voice_over
	
	# Re-enable buttons
	if sneller_button:
		sneller_button.disabled = false
	if langzamer_button:
		langzamer_button.disabled = false
	if game_manager:
		game_manager.set_layer_switch_buttons_enabled(true)
		uiManager.play_pause_button.disabled = false
		record_song_button.disabled = false
	
	if layer_voice_over_0:
		layer_voice_over_0.record_layer_button.disabled = false
	if layer_voice_over_1:
		layer_voice_over_1.record_layer_button.disabled = false
	
	# Restore volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), 0.0)
	
	finished = true
	
	stopped_recording.emit()
