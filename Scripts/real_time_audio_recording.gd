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
var bpm_manager: Node
var layer_manager: Node
var ui_manager: Node

func _ready():

	# Get manager references
	song_voice_over = %SongVoiceOver
	bpm_manager = %BpmManager
	layer_manager = %LayerManager
	ui_manager = %UiManager

	# Init record button
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
	if recording and progress_bar and layer_manager and bpm_manager:
		var layers_amount = layer_manager.layers_amount
		var beats_amount = bpm_manager.beats_amount
		var base_time_per_beat = bpm_manager.base_time_per_beat
		var total_time = layers_amount * beats_amount * base_time_per_beat
		if total_time > 0:
			progress_bar.value = recording_timer / total_time

	# Debug
	if Input.is_action_just_pressed("f1"):
		if not recording:
			start_recording_master()
		else:
			stop_recording_master()

func start_recording_master():
	print("Starting Recording")
	recording = true
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)

	# Also record voice over
	if song_voice_over:
		song_voice_over.should_record = true

	if ui_manager and ui_manager.metronome_toggle:
		ui_manager.metronome_toggle.button_pressed = false

	if ui_manager and ui_manager.has_method("close_count_down"):
		ui_manager.close_count_down()

func on_top():
	if recording:
		stop_recording_master()
	elif should_record:
		start_recording_master()

func _on_button():
	if not recording and not should_record:
		if ui_manager and ui_manager.layer_loop_toggle:
			ui_manager.layer_loop_toggle.button_pressed = true
		should_record = not should_record

		# Disable buttons during recording
		_disable_buttons(true)

		# Metronoom aan
		if ui_manager and ui_manager.metronome_toggle:
			ui_manager.metronome_toggle.button_pressed = true

		# 4 beats voor de eerste noot op eerste laag
		if layer_manager:
			var last_layer = layer_manager.layers_amount - 1
			layer_manager.switch_layer(last_layer)

		if bpm_manager:
			bpm_manager.current_beat = bpm_manager.beats_amount / 2

			# Playing true
			bpm_manager.playing = true

		# Also play metronome sound on first beat
		var game_manager = get_node_or_null("%GameManager")
		if game_manager and game_manager.has_method("play_extra_sfx") and game_manager.has("metronome_sfx"):
			game_manager.play_extra_sfx(game_manager.metronome_sfx)

		if game_manager and game_manager.has_method("show_count_down"):
			game_manager.show_count_down()

	elif not recording and should_record:
		# Cancel should record
		should_record = not should_record

		# Enable buttons
		_disable_buttons(false)

		# Stop tic sounds
		if ui_manager and ui_manager.metronome_toggle:
			ui_manager.metronome_toggle.button_pressed = false

		# Stop layer looping
		if ui_manager and ui_manager.layer_loop_toggle:
			ui_manager.layer_loop_toggle.button_pressed = false

		# Close countdown
		var game_manager = get_node_or_null("%GameManager")
		if game_manager and game_manager.has_method("close_count_down"):
			game_manager.close_count_down()

func stop_recording_master():
	print("Stopping Recording")
	recording = false
	should_record = false
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		recording_result = audio_effect_record.get_recording()

	recording_length = recording_timer
	finished = true

	# Stop tic sounds
	if ui_manager and ui_manager.metronome_toggle:
		ui_manager.metronome_toggle.button_pressed = false

	# Re-enable buttons
	_disable_buttons(false)

func _disable_buttons(disabled: bool):
	if song_voice_over:
		if song_voice_over.sneller_button:
			song_voice_over.sneller_button.disabled = disabled
		if song_voice_over.langzamer_button:
			song_voice_over.langzamer_button.disabled = disabled
		if song_voice_over.record_song_button:
			song_voice_over.record_song_button.disabled = disabled

	if layer_manager and layer_manager.has_method("set_layer_switch_buttons_enabled"):
		layer_manager.set_layer_switch_buttons_enabled(not disabled)

	if ui_manager:
		if ui_manager.play_pause_button:
			ui_manager.play_pause_button.disabled = disabled
		if ui_manager.layer_loop_toggle:
			ui_manager.layer_loop_toggle.disabled = disabled

	var layer_voice_over_0 = get_node_or_null("%LayerVoiceOver0")
	var layer_voice_over_1 = get_node_or_null("%LayerVoiceOver1")
	if layer_voice_over_0 and "record_layer_button" in layer_voice_over_0:
		layer_voice_over_0.record_layer_button.disabled = disabled
	if layer_voice_over_1 and "record_layer_button" in layer_voice_over_1:
		layer_voice_over_1.record_layer_button.disabled = disabled
